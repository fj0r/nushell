use common.nu *
use libs/db.nu *

export def cmpl-scratch-id [] {
    sqlx "select id, title,
        case parent_id when -1 then '#' else '' end as root
        from scratch order by updated desc;"
    | each { $"($in.id) #($in.root) ($in.title)" }
}

export def cmpl-untagged-root-scratch [ctx] {
    let ts = term size
    let rw = $ts.columns - 8
    let ch = $ts.rows - 5
    let cond = if (scope commands | where name == 'argx parse' | is-not-empty) {
        let c = $ctx | argx parse | get opt
        mut r = []
        if ($c.kind? | is-not-empty) { $r ++= $"s.kind = (Q $c.kind)" }
        if ($c.preset? | is-not-empty) { $r ++= $"p.preset = (Q $c.preset)" }
        if ($r | is-empty) { "" } else { $"and ($r | str join ' and ')" }
    }
    let q = $"select s.id as value,
        substr\(
            updated || '│' ||
            printf\('%-10s', s.kind\) || '│' ||
            printf\('%-10s', p.preset\) || '│' ||
            ltrim\(s.title || ' '\) || '│' || ltrim\(s.body\),
            0 , ($rw)
        \) as description
    from scratch as s
    left outer join scratch_tag as t on s.id = t.scratch_id
    left outer join scratch_preset as p on s.id = p.scratch_id
    where t.tag_id is null and s.parent_id = -1 and s.deleted = '' ($cond)
    order by updated desc limit ($ch);"
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

export def cmpl-accumulator [] {
    $env.SCRATCH_ACCUMULATOR | columns
}
