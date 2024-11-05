use common.nu *

export def cmpl-scratch-id [] {
    sqlx "select id, title,
        case parent_id when -1 then '#' else '' end as root
        from scratch order by updated desc;"
    | each { $"($in.id) #($in.root) ($in.title)" }
}

export def cmpl-untagged-scratch-id [] {
    let rw = (term size).columns - 8
    let q = $"select s.id as value,
        substr\(
            updated || '│' ||
            printf\('%-10s', s.kind\) || '│' ||
            printf\('%-10s', p.preset\) || '│' ||
            ltrim\(s.title || ' '\) || '...' || ltrim\(s.body\),
            0 , ($rw)
        \) as description
    from scratch as s
    left outer join scratch_tag as t on s.id = t.scratch_id
    left outer join scratch_preset as p on s.id = p.scratch_id
    where t.tag_id is null
    order by updated desc limit 20;"
    sqlx $q
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
