use common.nu *

export def cmpl-scratch-id [] {
    sqlx "select id, title,
        case parent_id when -1 then '#' else '' end as root
        from scratch order by updated desc;"
    | each { $"($in.id) #($in.root) ($in.title)" }
}

export def cmpl-untagged-scratch-id [] {
    sqlx $"select id as value, updated || '│' || printf\('%10s', kind\) || '│' ||
        case title when '' then '...' || substr\(ltrim\(body\), 0, 20\) else title end  as description
        from scratch
        left outer join scratch_tag on scratch.id = scratch_id
        where tag_id is null
        order by updated desc limit 10;"
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
