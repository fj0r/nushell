export def 'cmp-delete' [] {
    [trash]
}

export def 'cmp-level' [] {
    0..<5
}

export def 'cmp-todo-id' [] {
    open $env.TODO_DB
    | query db 'select id, title from todo;'
    | each { $"($in.id) # ($in.title)" }
}

export def 'cmp-tag-id' [] {
    open $env.TODO_DB
    | query db 'select id, name from tags;'
    | each { $"($in.id) # ($in.name)" }
}

export def 'cmp-tag' [] {
    open $env.TODO_DB
    | query db 'select name from tags;'
    | get name
}
