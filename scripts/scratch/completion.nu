use common.nu *

export def cmpl-sid [] {
    sqlx 'select id, title from scratch order by updated desc;'
    | each { $"($in.id) # ($in.title)" }
}

export def cmpl-scratch-id [] {
    sqlx $"select id as value, updated || '│' || kind || '│' ||
        case title when '' then '...' || substr\(ltrim\(body\), 0, 20\) else title end  as description
        from scratch order by updated desc limit 10;"
}

export def cmpl-sort [] {
    [created, updated, deadline, done, important, urgent]
}


export def cmpl-relevant-id [] {
    sqlx 'select id, name from person;'
    | each { $"($in.id) # ($in.name)" }
}


export def cmpl-todo-md [] {
    ls **/TODO.md | get name
}
