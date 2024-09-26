use common.nu *

export def 'cmp-delete' [] {
    [trash]
}

export def 'cmp-level' [] {
    0..<5
}

export def 'cmp-del-level' [] {
    [tag category]
}

export def 'cmp-sort' [] {
    [created, updated, deadline, done, important, urgent]
}

export def 'cmp-todo-id' [] {
    run 'select id, title from todo;'
    | each { $"($in.id) # ($in.title)" }
}

export def 'cmp-tag-id' [] {
    run 'select id, name from tag;'
    | each { $"($in.id) # ($in.name)" }
}

export def 'cmp-tag' [] {
    run 'select name from tag;'
    | get name
}

export def 'cmp-category' [] {
    run 'select c.name as category, t.name as tag
        from category as c
        join tag as t on t.category_id = c.id'
    | each { $"($in.category):($in.tag)" }
}

