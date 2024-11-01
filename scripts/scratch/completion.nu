use common.nu *

export def cmpl-sid [] {
    run 'select id, title from scratch order by updated desc;'
    | each { $"($in.id) # ($in.title)" }
}

export def cmpl-scratch-id [] {
    run $"select id as value, updated || '│' || kind || '│' ||
        case title when '' then '...' || substr\(ltrim\(body\), 0, 20\) else title end  as description
        from scratch order by updated desc limit 10;"
}

export def cmpl-sort [] {
    [created, updated, deadline, done, important, urgent]
}


export def cmpl-relevant-id [] {
    run 'select id, name from person;'
    | each { $"($in.id) # ($in.name)" }
}


export def cmpl-tag [] {
    run $"with (tag-tree) select * from tags" | get name | filter { $in | is-not-empty }
}

export def cmpl-tag-id [] {
   run $"with (tag-tree) select * from tags" | each { $"($in.id) # ($in.name)" }
}

export def cmpl-todo-md [] {
    ls **/TODO.md | get name
}
