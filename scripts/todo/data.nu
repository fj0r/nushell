use completion.nu *
use common.nu *
use format.nu *

# add todo
export def 'todo add' [
    --important(-i): int@cmp-level
    --urgent(-u): int@cmp-level
    --parent(-p): int@cmp-todo-id
    --tag(-t): list<string@cmp-category>
    --deadline(-d): duration
    --done(-D)
    --desc: string=''
    --batch(-b)
    title?: string
] {
    let title = if ($title | is-empty) { 'untitled' } else { $title }
    let data = if not $batch {
        let input = $"($title)\n($desc)" | block-edit $"add-todo-XXX.todo" | lines
        {
            title: ($input | first)
            desc: ($input | range 1.. | str join (char newline))
        }
    } else {
        {
            title: $title
            desc: $desc
        }
    }
    mut attrs = {}
    if ($important | is-not-empty) { $attrs.important = $important }
    if ($urgent | is-not-empty) { $attrs.urgent = $urgent }
    if ($parent | is-not-empty) { $attrs.parent_id = $parent }
    if ($deadline | is-not-empty) { $attrs.deadline = (date now) + $deadline | fmt-date }
    if ($done | is-not-empty) { $attrs.done = (if $done { 1 } else { 0 }) }

    let keys = [created, updated, title, description, ...($attrs | columns)]
    | str join ','

    let now = date now | fmt-date
    let vals = [$now, $now, $data.title, $data.desc, ...($attrs | values)]
    | each { Q $in }
    | str join ','

    let id = run $"insert into todo \(($keys)\) values \(($vals)\) returning id;"
    | first
    | get id
    print $"(ansi grey)Todo created successfully: ($id)(ansi reset)"

    if ($tag | is-not-empty) {
        let sub = $tag | cat-to-tag-id $id
        run $"insert into todo_tag ($sub);"
    }
}

# done todo
export def 'todo done' [
    id: int@cmp-todo-id
    --reverse(-r)
] {
    let d = if $reverse { 0 } else { 1 }
    run $'update todo set done = ($d) where id = ($id);'
}

# todo tag
export def 'todo tag' [
    id: int@cmp-todo-id
    --tag(-t): list<string@cmp-category>
    --remove(-r)
] {
    let s = if $remove {
        let sub = $tag | cat-to-tag-id
        $"delete from todo_tag where todo_id = ($id) and tag_id in \(($sub)\);"
    } else {
        let sub = $tag | cat-to-tag-id $id
        $"insert into todo_tag ($sub)
          on conflict \(todo_id, tag_id\) do nothing
        ;"
    }
    run $s
}


# todo edit
export def 'todo edit' [
    id: int@cmp-todo-id
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
export def 'todo move' [
    id: int@cmp-todo-id
    to: int@cmp-todo-id
] {
    run $"update todo set parent_id = ($to) where id = ($id);"
}

# todo show
export def 'todo show' [
    ...tags: any@cmp-category
    --all(-a)
    --important(-i): int@cmp-level
    --urgent(-u): int@cmp-level
    --updated: duration
    --created: duration
    --deadline: duration
    --sort(-s): list<string@cmp-sort>
    --undone(-U)
    --raw
    --debug
] {
    let sortable = [
        created, updated, deadline,
        done, important, urgent
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
    if not $all {
        let x = [':trash'] | cat-to-tag-id | run $in | get 0.id
        $cond ++= $"todo.id not in \(select todo_id from todo_tag where tag_id in \(($x)\)\)"
    }
    if ($tags | is-not-empty) {
        let tag_cond = $tags | cat-to-tag-id --and=(not $all)
        dbg -t tag-cond $debug $tag_cond
        let tag_id = run $tag_cond
        | get id
        | str join ', '
        #$cond ++= $"todo_tag.tag_id not in \(1\)"
        $cond ++= $"todo.id in \(select todo_id from todo_tag where tag_id in \(($tag_id)\)\)"
    }
    let now = date now
    if ($important | is-not-empty) { $cond ++= $"important >= ($important)"}
    if ($urgent | is-not-empty) { $cond ++= $"urgent >= ($urgent)"}
    if ($updated | is-not-empty) { $cond ++= $"updated >= ($now - $updated | fmt-date | Q $in)"}
    if ($created | is-not-empty) { $cond ++= $"created >= ($now - $created | fmt-date | Q $in)"}
    if ($deadline | is-not-empty) { $cond ++= $"deadline >= ($now - $deadline | fmt-date | Q $in)"}
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

    if $raw { $r } else { $r | todo format }
}


# delete todo in categories
export def 'todo cat purge' [
    --level(-L): string@cmp-del-level
    ...tags: string@cmp-category
] {
    let ns = $tags | split-cat
    let tag_id = run ($tags | cat-to-tag-id) | get id
    let id = run $"delete from todo where id in \(
        select todo_id from todo_tag where tag_id in \(($tag_id | str join ', ')\)
        \) returning id" | get id
    run $"delete from todo_tag where todo_id in \(($id | str join ', ')\)"
    if $level in [tag category] {
        run $"delete from tag where id in \(($tag_id | str join ', ')\)"
    }
    if $level in [category] {
        run $"delete from category where name in \(($ns | columns | each {Q $in} | str join ', ')\);"
    }
}

# add categories
export def 'todo cat add' [...categories] {
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

export def 'todo cat rename' [from:string@cmp-category to] {
    run $"update tag set name = (Q $to) where name = (Q $from)"
}
