use completion.nu *
use common.nu *
use format.nu *

# add todo
export def todo-add [
    --important(-i): int@cmpl-level
    --urgent(-u): int@cmpl-level
    --challenge(-c): int@cmpl-level
    --parent(-p): int@cmpl-todo-id
    --tag(-t): list<string@cmpl-tag-id>
    --deadline(-d): duration
    --done(-x)
    --desc: string=''
    --relevant(-r): int@cmpl-relevant-id
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
        relevant: $relevant
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
        let t = run $"(tag-tree) select tags.name
        from todo join todo_tag on todo.id = todo_tag.todo_id
        join tags on todo_tag.tag_id = tags.id
        where todo.id = ($parent)"
        | get name
        $tag ++= $t
    }
    if ($tag | is-not-empty) {
        for id in $ids {
            run $"(tag-tree) insert into todo_tag
            select ($id) as todo_id, tags.id as tag_id
            from tags where tags.name in \(($tag | each { Q $in } | str join ', ')\);"
        }
    }

    for id in $ids {
        todo-done $id --reverse=(not $done)
    }

    return $ids
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
    --tag(-t): list<string@cmpl-tag>
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
            let children = run $"(tag-tree) select tags.id from tags where name in \(($tag | each {Q $in} | str join ',')\)" | get id
            run $"delete from todo_tag where todo_id in \(($ids | str join ',')\) and tag_id in \(($children | str join ',')\);"
        } else {
            for id in $ids {
                let children = $"select ($id), tags.id from tags where name in \(($tag | each {Q $in} | str join ',')\)"
                run $"(tag-tree) insert into todo_tag ($children)
                  on conflict \(todo_id, tag_id\) do nothing
                ;"
            }
        }
    }
}

def 'uplevel done' [pid now done:bool] {
    mut p = $pid
    loop {
        if $done {
            # Check if all nodes at the current level are Done
            let all_done = (run $"
                (tag-tree), p as \(
                    select tags.id from tags where name = ':trash'
                \), x as \(
                    select d.parent_id, d.id,
                    case t.tag_id in \(p.id\) when true then 0 else 1 end as c
                    from p, todo as d
                    join todo_tag as t on d.id = t.todo_id
                    where d.parent_id = ($p) and d.done = 0
                    group by d.id, d.done
                \) select sum\(c\) as c from x;
                " | get 0.c | default 0) == 0
            if $all_done {
                $p = (run $"update todo set done = 1, updated = ($now) where id = ($p) returning parent_id;" | get 0.parent_id)
            } else {
                run $"update todo set done = 0, updated = ($now) where id = ($p)"
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
    | db-upsert todo id

}

# todo move
export def todo-move [
    id: int@cmpl-todo-id
    to: int@cmpl-todo-id
] {
    let now = date now | fmt-date | Q $in
    let pid = run $"select parent_id from todo where id = ($id);" | get 0.parent_id
    run $"update todo set parent_id = ($to) where id = ($id);"
    uplevel done $pid $now true
    uplevel done $to $now true
}

# todo list
export def todo-list [
    ...tags: any@cmpl-tag
    --parent(-p): int@cmpl-todo-id
    --search(-s): string
    --all(-a)
    --important(-i): int@cmpl-level
    --urgent(-u): int@cmpl-level
    --challenge(-c): int@cmpl-level
    --updated: duration
    --created: duration
    --deadline: duration
    --relevant(-r): int@cmpl-relevant-id
    --sort(-s): list<string@cmpl-sort>
    --work-in-process(-W)
    --finished(-F)
    --untagged(-U)
    --no-branch(-N)
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
        "todo.id as id", "todo.parent_id as parent_id",
        title, description, ...$sortable, relevant,
        "tags.name as tag"
    ] | str join ', '

    let sort = if ($sort | is-empty) { ['created'] } else { $sort }
    | each { $"todo.($in)" }
    | str join ', '

    mut cond = []
    mut flt = {and: [], not: []}

    let trash_id = run $"select tag.id from tag join tag as t on tag.id = t.parent_id where tag.name = '' and t.name = 'trash'" | get 0.id
    let trash_sid = run $"(tag-tree --parent-id $trash_id) select id from tags" | get id
    let trash_ids = [$trash_id, ...$trash_sid]
    let tidq = "select todo_tag.todo_id from todo_tag join tags on tags.id = todo_tag.tag_id"
    let tidq_filter_trash = "tags.name = ':trash'"
    # TODO:
    #let tidq_filter_trash = $"todo_tag.id in \(($trash_ids | into string | str join ',')\)"
    $cond ++= match [$all ($tags | is-empty)] {
        [true false] => $"true"
        [true true] => $"todo.id not in \(($tidq) where tags.hidden\)"
        [false false] => $"todo.id not in \(($tidq) where ($tidq_filter_trash)\)"
        [false true] => $"todo.id not in \(($tidq) where \(($tidq_filter_trash)\) or tags.hidden\)"
    }

    if ($tags | is-not-empty) {
        let ts = $tags | each { Q $in } | str join ', '
        $cond ++= $"todo.id in \(select todo_id from todo_tag join tags on tag_id = tags.id where tags.name in \(($ts)\)\)"
    } else {
        if $untagged {
            $cond ++= $"todo_tag.tag_id is null"
        }
    }

    if ($parent | is-not-empty) {
        let children = $"with recursive s as \(
        select id, parent_id from todo where id = ($parent)
        union select t.id, t.parent_id from todo as t join s on t.parent_id = s.id
        \) select id from s"
        $cond ++= $"todo.id in \(($children)\)"
    }

    let now = date now
    if ($search | is-not-empty) { $cond ++= $"title like '%($search)%'" }
    if ($challenge | is-not-empty) { $cond ++= $"challenge >= ($challenge)"}
    if ($important | is-not-empty) { $cond ++= $"important >= ($important)"}
    if ($urgent | is-not-empty) { $cond ++= $"urgent >= ($urgent)"}
    if ($updated | is-not-empty) { $cond ++= $"updated >= ($now - $updated | fmt-date | Q $in)"}
    if ($created | is-not-empty) { $cond ++= $"created >= ($now - $created | fmt-date | Q $in)"}
    if ($deadline | is-not-empty) { $cond ++= $"deadline >= ($now - $deadline | fmt-date | Q $in)"}
    if ($relevant | is-not-empty) { $cond ++= $"relevant = ($relevant)"}
    if ($work_in_process) { $cond ++= $"done = 0" }
    if ($finished) { $cond ++= $"done = 1" }

    let $cond = if ($cond | is-empty) { '' } else { $cond | str join ' and ' | $"where ($in)" }

    dbg $debug $cond -t cond
    let stmt = $"(tag-tree) select ($fields) from todo
        left outer join todo_tag on todo.id = todo_tag.todo_id
        left outer join tags on todo_tag.tag_id = tags.id
        ($cond) order by ($sort);"
    dbg $debug $stmt -t stmt
    let r = run $stmt
    | group-by id
    | items {|k, x| $x | first | insert tags ($x | select tag) | reject tag }

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

    let r = if $no_branch {
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


# delete todo in tag
export def todo-tag-clean [
    ...tags: string@cmpl-tag
    --with-tag(-T)
] {
    let tag_id = run $"(tag-tree) select id from tags
        where name in \(($tags | each {Q $in} | str join ', ')\)"
    | get id
    let id = run $"delete from todo where id in \(
        select todo_id from todo_tag where tag_id in \(($tag_id | str join ', ')\)
        \) returning id" | get id
    dbg true -t 'delete todo' $id
    let tid = run $"delete from todo_tag where todo_id in \(($id | str join ', ')\)
        returning todo_id, tag_id"
    dbg true -t 'delete todo_tag' $tid
    if $with_tag {
        run $"delete from tag where id in \(($tag_id | str join ', ')\)"
        dbg true -t 'delete tag' $tag_id
    }
}

# add tag
export def todo-tag-add [...tags] {
    for tag in $tags {
        let ts = $tag | split row ':'
        mut pid = run $"insert into tag \(parent_id, name\) values \(-1, (Q $ts.0)\)
            on conflict \(parent_id, name\) do update set parent_id = EXCLUDED.parent_id
            returning id, name;"
            | get 0.id
        for t in ($ts | range 1..) {
            $pid = run $"insert into tag \(parent_id, name\) values
            \(($pid), (Q $t)\)
            on conflict \(parent_id, name\) do update set parent_id = EXCLUDED.parent_id
            returning id, name;"
            | get 0.id
        }
    }
}

export def todo-tag-rename [from:string@cmpl-tag-id to] {
    run $"update tag set name = (Q $to) where id = ($from)"
}

export def todo-tag-hidden [tag:string@cmpl-tag-id] {
    run $"update tag set hidden = not hidden where id = ($tag)"
}

export def todo-title [id: int@cmpl-todo-id] {
    run $'select title from todo where id = ($id);'
    | get 0.title
}

export def todo-body [id: int@cmpl-todo-id] {
    run $'select description from todo where id = ($id);'
    | get 0.description
}

export def todo-export [
    ...tags: any@cmpl-tag
] {
    todo-list ...$tags --raw | todo-tree | to json
}

