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

    let keys = [created, updated, title, content, ...($attrs | columns)]
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
        let t = run $"with (tag-tree) select tags.name
        from todo join todo_tag on todo.id = todo_tag.todo_id
        join tags on todo_tag.tag_id = tags.id
        where todo.id = ($parent)"
        | get name
        $tag ++= $t
    }
    if ($tag | is-not-empty) {
        for id in $ids {
            run $"with (tag-tree) insert into todo_tag
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
            let children = run $"with (tag-tree) select tags.id from tags where name in \(($tag | each {Q $in} | str join ',')\)" | get id
            run $"delete from todo_tag where todo_id in \(($ids | str join ',')\) and tag_id in \(($children | str join ',')\);"
        } else {
            for id in $ids {
                let children = $"select ($id), tags.id from tags where name in \(($tag | each {Q $in} | str join ',')\)"
                run $"with (tag-tree) insert into todo_tag ($children)
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
            let all_done = (run $"select count\(1\) as c from todo
                where parent_id = ($p) and deleted = '' and done = 0"
            | get 0.c | default 0) == 0
            if $all_done {
                let r = run $"update todo set done = 1, updated = ($now) where id = ($p) returning parent_id;"
                if ($r | is-empty) {
                    break
                } else {
                    $p = $r | get 0.parent_id
                }
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

# done delete
export def todo-delete [
    ...id: int@cmpl-todo-id
    --reverse(-r)
] {
    let now = date now | fmt-date | Q $in
    let d = if $reverse { '' } else { $now }
    let ids = $id | str join ','
    let pid = run $"update todo set deleted = ($d) where id in \(($ids)\) returning parent_id;" | get parent_id
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
    --trash(-T) # show trash
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
        title, content, ...$sortable, relevant,
        "tags.name as tag"
    ] | str join ', '

    let sort = if ($sort | is-empty) { ['created'] } else { $sort }
    | each { $"todo.($in)" }
    | str join ', '

    mut cond = []

    ## A todo may have multiple associated tags
    ## so instead of filtering by tag_id, we need to filter by todo_id
    # (not $trash) show deleted
    let exclude_deleted = $"todo.deleted = ''"
    # ($tags | is-empty) tags.hidden = 0
    let exclude_tags_hidden = "tags.hidden = 0"
    # ($untagged)
    let include_untagged = "tags.name is null"
    dbg $debug {trash: $trash, notags: ($tags | is-empty), untagged: $untagged} -t cond
    $cond ++= match [$trash ($tags | is-empty) $untagged] {
        # --untagged
        [false true true] => $"($exclude_deleted) and ($include_untagged)"
        #
        [false true false] => $"($exclude_deleted) and ($exclude_tags_hidden)"
        # [ --untagged tag ]
        [false false true] => $"($exclude_deleted) and ($include_untagged)"
        # tag
        [false false false] => $"($exclude_deleted)"
        # --trash --untagged
        [true true true] => $"\(($exclude_tags_hidden) or ($include_untagged)\)"
        # --trash
        [true true false] => $exclude_tags_hidden
        # --trash [ --untagged tag ]
        [true false true] => $include_untagged
        # --trash tag
        [true false false] => "true"
    }

    mut flt = {and:[], not:[]}
    if ($tags | is-not-empty) {
        $flt = $tags | tag-group
        let tags = $flt.normal
        let tags_id = run $"with (tag-tree), tid as \(
            select id from tags where name in \(($tags | each {Q $in} | str join ', ')\)
        \), (tag-branch ids --where 'id in (select id from tid)')
        select id from ids"
        | get id | each { $in | into string } | str join ', '
        $cond ++= $"todo.id in \(select todo_id from todo_tag where tag_id in \(($tags_id)\)\)"
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

    let stmt = $"with (tag-tree) select ($fields) from todo
        left outer join todo_tag on todo.id = todo_tag.todo_id
        left outer join tags on todo_tag.tag_id = tags.id
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

    let r = if $no_branch {
        $r
    } else {
        let ids = $r | get id | str join ', '
        let fp = [id, parent_id, title]
        let ft = $fp | each { $"t.($in)" } | str join ', '
        let x = run $"with recursive p as \(
            select ($fp | str join ', '), 2 as done from todo where id in \(($ids)\)
            union all
            select ($ft), 2 as done from todo as t join p on p.parent_id = t.id
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
    let tags_id = run $"with (tag-tree), tid as \(
        select id from tags where name in \(($tags | each {Q $in} | str join ', ')\)
    \), (tag-branch ids --where 'id in (select id from tid)')
    select id from ids"
    | get id | each { $in | into string } | str join ', '
    let id = run $"delete from todo where id in \(
        select todo_id from todo_tag where tag_id in \(($tags_id)\)
        \) returning id" | get id
    dbg true -t 'delete todo' $id
    let tid = run $"delete from todo_tag where todo_id in \(($id | str join ', ')\)
        returning todo_id, tag_id"
    dbg true -t 'delete todo_tag' $tid
    if $with_tag {
        run $"delete from tag where id in \(($tags_id)\)"
        dbg true -t 'delete tag' $tags_id
    }
}

# add tag
export def todo-tag-add [...tags] {
    mut ids = []
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
        $ids ++= $pid
    }
    return $ids
}

export def todo-tag-rename [from:string@cmpl-tag-id to] {
    run $"update tag set name = (Q $to) where id = ($from)"
}

export def todo-tag-hidden [tag:int@cmpl-tag-id] {
    run $"update tag set hidden = not hidden where id = ($tag) returning hidden"
}

export def todo-title [id: int@cmpl-todo-id] {
    run $'select title from todo where id = ($id);'
    | get 0.title
}

export def todo-body [id: int@cmpl-todo-id] {
    run $'select content from todo where id = ($id);'
    | get 0.content
}

export def todo-export [
    ...tags: any@cmpl-tag
] {
    todo-list ...$tags --raw | todo-tree | to json
}

