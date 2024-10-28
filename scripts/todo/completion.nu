use common.nu *

export def cmpl-delete [] {
    [trash]
}

export def cmpl-level [] {
    0..<5
}

export def cmpl-sort [] {
    [created, updated, deadline, done, important, urgent]
}

export def cmpl-relevant-id [] {
    run 'select id, name from person;'
    | each { $"($in.id) # ($in.name)" }
}

export def cmpl-todo-id [] {
    run 'select id, title from todo;'
    | each { $"($in.id) # ($in.title)" }
}

export def cmpl-tag [] {
    run $"(tag-tree) select * from tags" | get name

}

export def cmpl-tag-id [] {
   run $"(tag-tree) select * from tags" | each { $"($in.id) # ($in.name)" }
}

export def cmpl-todo-md [] {
    ls **/TODO.md | get name
}
