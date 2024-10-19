use completion.nu *
use common.nu *
use format.nu *

def 'uplevel done' [pid now done:bool] {
    mut p = $pid
    loop {
        if $done {
            # Check if all nodes at the current level are Done
            let all_done = (run $"select count\(1\) as c from todo where parent_id = ($p) and done = 0" | get 0.c) == 0
            if $all_done {
                $p = (run $"update todo set done = 1, updated = ($now) where id = ($p) returning parent_id;" | get 0.parent_id)
            } else {
                break
            }
        } else {
            let x = run $"update todo set done = 0, updated = ($now) where id = ($p) and done = 1 returning parent_id;"
            if ($x | is-empty) {
                break
            } else {
                $p = $x | get 0.parent_id
            }
        }
    }
}

# add todo
export def todo-add [
    --important(-i): int@cmpl-level
    --urgent(-u): int@cmpl-level
    --challenge(-c): int@cmpl-level
    --parent(-p): int@cmpl-todo-id
    --tag(-t): list<string@cmpl-category>
    --deadline(-d): duration
    --done(-x)
    --desc: string=''
    --edit(-e)
    title?: string
] {
    let o = $in
    let title = if ($title | is-empty) {
        if ($o | is-empty) {
            'untitled'
        } else {
            $o
        }
    } else {
        $title
    }
    let data = if $edit {
        let input = $"($title)\n($desc)" | block-edit $"add-todo-XXX.todo" | split row "\n---\n"
        $input | each {|x|
            let y = $x | lines
            {
                title: ($y | first)
                desc: ($y | range 1.. | str join (char newline))
            }
        }

    } else {
        [
            {
                title: $title
                desc: $desc
            }
        ]
    }
    let attrs = {
        important: $important
        urgent: $urgent
        challenge: $challenge
        parent_id: $parent
        deadline: (if ($deadline | is-not-empty) {(date now) + $deadline | fmt-date})
        done: (if $done { 1 } else { 0 })
    } | filter-empty

    let keys = [created, updated, title, description, ...($attrs | columns)]
    | str join ','

    let now = date now | fmt-date
    let vals = $data
    | each {|x|
        [$now, $now, $x.title, $x.desc, ...($attrs | values)]
        | each { Q $in }
        | str join ','
        | $"\(($in)\)"
    }
    | str join ','

    let ids = run $"insert into todo \(($keys)\) values ($vals) returning id;"
    | get id
    dbg true -t 'todo created successfully' $ids

    mut tag = $tag | default []
    # Inheriting tags when child nodes are added
    if ($parent | is-not-empty) {
        let t = run $"select category.name || ':' || tag.name as tag from todo join todo_tag on todo.id = todo_tag.todo_id join tag on todo_tag.tag_id = tag.id join category on tag.category_id = category.id where todo.id = ($parent)"
        | get tag
        $tag ++= $t
    }
    if ($tag | is-not-empty) {
        for id in $ids {
            let children = $tag | split-cat | cat-to-tag-id $id
            run $"insert into todo_tag ($children);"
        }
    }

    for id in $ids {
        todo-done $id --reverse=(not $done)
    }
}

# todo set
export def todo-attrs [
    ...ids: int@cmpl-todo-id
    --important(-i): int@cmpl-level
    --urgent(-u): int@cmpl-level
    --challenge(-c): int@cmpl-level
    --parent(-p): int@cmpl-todo-id
    --deadline(-d): duration
    --done(-x): int
    --tag(-t): list<string@cmpl-category>
    --remove(-r)
] {
    let args = {
        important: $important
        urgent: $urgent
        challenge: $challenge
        parent_id: $parent
        deadline: (if ($deadline | is-not-empty) {(date now) + $deadline | fmt-date})
    }
    | filter-empty

    if ($args | is-not-empty) {
        let attrs = $args
        | items {|k, v| $"($k) = (Q $v)"}
        | str join ','
        run $"update todo set ($attrs) where id in \(($ids | str join ',')\);"
    }

    if ($done | is-not-empty) {
        for id in $ids {
            todo-done $id --reverse=($done == 0)
        }
    }

    if ($tag | is-not-empty) {
        if $remove {
            let children = $tag | split-cat | cat-to-tag-id
            run $"delete from todo_tag where todo_id in \(($ids | str join ',')\) and tag_id in \(($children)\);"
        } else {
            for id in $ids {
                let children = $tag | split-cat | cat-to-tag-id $id
                run $"insert into todo_tag ($children)
                  on conflict \(todo_id, tag_id\) do nothing
                ;"
            }
        }
    }
}

# done todo
export def todo-done [
    ...id: int@cmpl-todo-id
    --reverse(-r)
] {
    let d = if $reverse { 0 } else { 1 }
    let now = date now | fmt-date | Q $in
    let ids = $id | str join ','
    let pid = run $"update todo set done = ($d), updated = ($now) where id in \(($ids)\) returning parent_id;" | get parent_id
    # update parents status
    for i in $pid {
        uplevel done $i $now (not $reverse)
    }
}

# todo edit
export def todo-edit [
    id: int@cmpl-todo-id
] {
    run $"select * from todo where id = ($id);"
    | first
    | to yaml
    | $"### Do not change the `id` \n($in)"
    | block-edit $"todo.XXX.yml"
    | from yaml
    | update updated (date now | fmt-date)
    | db-upsert $env.TODO_DB todo id

}

# todo move
export def todo-move [
    id: int@cmpl-todo-id
    to: int@cmpl-todo-id
] {
    run $"update todo set parent_id = ($to) where id = ($id);"
}

# todo list
export def todo-list [
    ...tags: any@cmpl-category
    --search(-s): string
    --all(-a)
    --important(-i): int@cmpl-level
    --urgent(-u): int@cmpl-level
    --challenge(-c): int@cmpl-level
    --updated: duration
    --created: duration
    --deadline: duration
    --sort(-s): list<string@cmpl-sort>
    --work-in-process(-W)
    --finished(-F)
    --untagged(-U)
    --no-parent(-N)
    --md(-m)
    --md-list(-l)
    --raw
    --debug
] {
    let sortable = [
        created, updated, deadline,
        done, important, urgent, challenge
    ]
    let fields = [
        "todo.id as id", parent_id,
        title, description, ...$sortable , delegate,
        "category.name || ':' || tag.name as tag"
    ] | str join ', '

    let sort = if ($sort | is-empty) { ['created'] } else { $sort }
    | each { $"todo.($in)" }
    | str join ', '

    mut cond = []
    mut flt = {and: [], not: []}
    if not $all {
        let tidq = "select todo_tag.todo_id from category
            join tag on category.id = tag.category_id
            join todo_tag on todo_tag.tag_id = tag.id
            where category.hidden"
        $cond ++= $"todo.id not in \(($tidq)\)"
    }
    if ($tags | is-not-empty) {
        let sc = $tags | split-cat
        let tag_cond = $sc | cat-to-tag-id --empty-as-all --and=(not $all)
        $flt = $sc | cat-filter
        dbg -t tag-cond $debug $tag_cond
        let tag_id = run $tag_cond
        | get id
        | str join ', '
        #$cond ++= $"todo_tag.tag_id not in \(1\)"
        $cond ++= $"todo.id in \(select todo_id from todo_tag where tag_id in \(($tag_id)\)\)"
    } else {
        if $untagged {
            $cond ++= $"todo_tag.tag_id is null"
        }
    }
    let now = date now
    if ($search | is-not-empty) { $cond ++= $"title like '%($search)%'" }
    if ($challenge | is-not-empty) { $cond ++= $"challenge >= ($challenge)"}
    if ($important | is-not-empty) { $cond ++= $"important >= ($important)"}
    if ($urgent | is-not-empty) { $cond ++= $"urgent >= ($urgent)"}
    if ($updated | is-not-empty) { $cond ++= $"updated >= ($now - $updated | fmt-date | Q $in)"}
    if ($created | is-not-empty) { $cond ++= $"created >= ($now - $created | fmt-date | Q $in)"}
    if ($deadline | is-not-empty) { $cond ++= $"deadline >= ($now - $deadline | fmt-date | Q $in)"}
    if ($work_in_process) { $cond ++= $"done = 0" }
    if ($finished) { $cond ++= $"done = 1" }
    let $cond = if ($cond | is-empty) { '' } else { $cond | str join ' and ' | $"where ($in)" }

    dbg $debug $cond -t cond
    let stmt = $"select ($fields) from todo
        left outer join todo_tag on todo.id = todo_tag.todo_id
        left outer join tag on todo_tag.tag_id = tag.id
        left outer join category on tag.category_id = category.id
        ($cond) order by ($sort);"
    dbg $debug $stmt -t stmt
    let r = run $stmt
    | group-by id
    | items {|k, x| $x | first | insert tags ($x | get tag) | reject tag }


    let flt = $flt
    let r = if ($flt.and | is-not-empty) or ($flt.not | is-not-empty) {
        $r
        | filter {|x|
            let n = not ($flt.not | any {|y| $y in $x.tags })
            let a = $flt.and | all {|y| $y in $x.tags }
            $n and $a
        }
    } else {
        $r
    }

    let r = if $no_parent {
        $r
    } else {
        let ids = $r | get id | str join ', '
        let fp = [id, parent_id, title, done]
        let ft = $fp | each { $"t.($in)" } | str join ', '
        let x = run $"with recursive p as \(
            select ($fp | str join ', ') from todo where id in \(($ids)\)
            union all
            select ($ft) from todo as t join p on p.parent_id = t.id
            \) select * from p;"
        $r | append $x | uniq-by id
    }

    if $raw { $r } else { $r | todo-format --md=$md --md-list=$md_list }
}


# delete todo in categories
export def todo-cat-clean [
    --level(-L): string@cmpl-del-level
    ...tags: string@cmpl-category
] {
    let ns = $tags | split-cat
    let tag_id = run ($tags | split-cat | cat-to-tag-id) | get id
    let id = run $"delete from todo where id in \(
        select todo_id from todo_tag where tag_id in \(($tag_id | str join ', ')\)
        \) returning id" | get id
    dbg true -t 'delete todo' $id
    let tid = run $"delete from todo_tag where todo_id in \(($id | str join ', ')\)
        returning todo_id, tag_id"
    dbg true -t 'delete todo_tag' $tid
    if $level in [tag category] {
        run $"delete from tag where id in \(($tag_id | str join ', ')\)"
        dbg true -t 'delete tag' $tag_id
    }
    if $level in [category] {
        run $"delete from category where name in \(($ns | columns | each {Q $in} | str join ', ')\);"
        dbg true -t 'delete category' ($ns | columns)
    }
}

# add categories
export def todo-cat-add [...categories] {
    let ns = $categories | split-cat
    let c = $ns | columns | each { $"\((Q $in)\)" } | str join ','
    let c = run $"insert into category \(name\) values ($c)
        on conflict \(name\) do update set name = EXCLUDED.name
        returning id, name;"
    for i in $c {
        let t = $ns | get $i.name -s
        let t = $t | each { $"\(($i.id), (Q $in)\)" } | str join ','
        run $"insert into tag \(category_id, name\) values ($t)
            on conflict \(category_id, name\) do nothing;"
    }
}

export def todo-cat-rename [from:string@cmpl-category to] {
    run $"update tag set name = (Q $to) where name = (Q $from)"
}

export def todo-cat-hidden [cat:string@cmpl-cat] {
    run $"update category set hidden = not hidden where id = ($cat)"
}

export def todo-title [id: int@cmpl-todo-id] {
    run $'select title from todo where id = ($id);'
    | get 0.title
}

export def todo-export [
    ...tags: any@cmpl-category
] {
    todo-list ...$tags --raw | todo-tree | to json
}

