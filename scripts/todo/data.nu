use completion.nu *
use common.nu *
use format.nu *

# add todo
export def 'todo add' [
    --important(-i): int@cmp-level
    --urgent(-u): int@cmp-level
    --parent(-p): int@cmp-todo-id
    --tag(-t): list<string@cmp-category>
    --duration(-d): duration
    --done(-D)
    --desc: string=''
    --batch(-b)
    title?: string
] {
    let now = date now | format date '%FT%H:%M:%S'
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
    if ($duration | is-not-empty) { $attrs.deadline = (date now) + $duration | format date '%FT%H:%M:%S' }
    if ($done | is-not-empty) { $attrs.done = (if $done { 1 } else { 0 }) }

    let keys = [created, updated, title, description, ...($attrs | columns)]
    | str join ','

    let vals = [$now, $now, $data.title, $data.desc, ...($attrs | values)]
    | each { Q $in }
    | str join ','

    let id = run $"insert into todo \(($keys)\) values \(($vals)\) returning id;"
    | first
    | get id
    print $"(ansi grey)Todo created successfully: ($id)(ansi reset)"

    if ($tag | is-not-empty) {
        let tags = $tag | each { Q $in } | str join ','
        run $"insert into todo_tag
            select ($id), t.id from tag as t
            join category as c on t.category_id = c.id
            where name in \(($tags)\);"
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

export def 'todo tag' [
    id: int@cmp-todo-id
    --tag(-t): string@cmp-category
    --remove(-r)
] {
    let tags = $tag | each { Q $in } | str join ','
    let s = if $remove {
        $"delete from todo_tag where todo_id = ($id) and tag_id in \(select id from tag where name in \(($tags)\)\);"
    } else {
        $"insert into todo_tag
        select ($id), t.id from tag as t where name in \(($tags)\)
        on conflict \(todo_id, tag_id\) do nothing
        ;"
    }
    run $s
}


export def 'todo edit' [
    id: int@cmp-todo-id
] {
    run $"select * from todo where id = ($id);"
    | first
    | to yaml
    | $"### Do not change the `id` \n($in)"
    | block-edit $"todo.XXX.yml"
    | from yaml
    | update updated (date now | format date '%FT%H:%M:%S')
    | db-upsert $env.TODO_DB todo id

}

export def 'todo move' [
    id: int@cmp-todo-id
    to: int@cmp-todo-id
] {
    run $"update todo set parent_id = ($to) where id = ($id);"
}

export def 'todo list' [
    --all(-a)
    --tag(-t): list<string>
    --important(-i): int
    --urgent(-u): int
    --duration(-d): duration
] {
    run $"select * from todo as t
        left outer join todo_tag as l on t.id = l.todo_id
        left outer join tag as g on l.tag_id = g.id
        order by t.created
    ;"
    | rename todo
    | select todo parent_id title description created updated deadline important urgent delegate name
    | group-by todo
    | items {|k, x| $x | first | insert tags ($x | get name) | reject name }
    | todo format
}

export def 'todo now' [

] {

}

export def 'todo delete' [
    --with-tag(-w)
    ...tags: string@cmp-delete
] {
    let ts = $tags | each { Q $in } | str join ','
    run $"delete from todo where id in \(
        select t.todo_id as id from todo_tag as t join tag as g
            on g.id = t.tag_id where g.name in \(($ts)\)
    \)"
    run $"delete from todo_tag where tag_id in \(
        select id from tag where name in \(($ts)\)
    \);"
    if $with_tag {
        run $"delete from tag where name in \($ts\);"
    }
}

# add categories
export def 'todo cat add' [...categories] {
    let ns = $categories | split-tag
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

export def 'todo cat rename' [from:string@cmp-tag to] {
    run $"update tag set name = (Q $to) where name = (Q $from)"
}
