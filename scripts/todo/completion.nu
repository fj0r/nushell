use common.nu *

export def 'cmpl-delete' [] {
    [trash]
}

export def 'cmpl-level' [] {
    0..<5
}

export def 'cmpl-del-level' [] {
    [tag category]
}

export def 'cmpl-sort' [] {
    [created, updated, deadline, done, important, urgent]
}

export def 'cmpl-todo-id' [] {
    run 'select id, title from todo;'
    | each { $"($in.id) # ($in.title)" }
}

export def 'cmpl-tag-id' [] {
    run 'select id, name from tag;'
    | each { $"($in.id) # ($in.name)" }
}

export def 'cmpl-tag' [] {
    run 'select name from tag;'
    | get name
}

export def 'cmpl-cat' [] {
    run $"select id as value, name || '(char tab)' || hidden as description from category"
}

export def 'cmpl-category' [] {
    run 'select c.name as category, t.name as tag
        from category as c
        join tag as t on t.category_id = c.id'
    | each { $"($in.category):($in.tag)" }
}

export def 'cmpl-todo-md' [] {
    ls **/TODO.md | get name
}
