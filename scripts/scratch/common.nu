use libs/db.nu *

export def filter-empty [] {
    $in
    | transpose k v
    | reduce -f {} {|i,a|
        if ($i.v | is-empty) {
            $a
        } else {
            $a | insert $i.k $i.v
        }
    }
}

export def add-kind [] {
    $in | table-upsert {
        default: {
            name: 'md'
            comment: "# "
            runner: 'file'
            cmd: ''
        }
        table: kind
        pk: name
        filter: {}
    }
}


export def tag-group [] {
    let x = $in
    mut $r = { not: [], and: [], normal: [] }
    for i in $x {
        match ($i | str substring ..<1) {
            '!' => { $r.not ++= $i | str substring 1.. }
            '&' => { $r.and ++= $i | str substring 1.. }
            _ => { $r.normal ++= $i}
        }
    }
    $r
}

export def tag-branch [table: string, --where: string] {
    let n = $"($table)_(random chars -l 3)"
    $"($table) as \(
        select id, parent_id, hidden, name from tag where ($where)
        union all
        select ($n).id, ($n).parent_id, ($n).hidden, ($table).name || ':' || ($n).name as name from tag as ($n)
        join ($table) on ($n).parent_id = ($table).id
    \)"
}

export def tag-tree [name?: string='tags' --where: string='parent_id in (-1)'] {
    let n = $"_(random chars -l 3)"
    let b = tag-branch $n --where $where
    $"recursive ($b), ($n)_1 as \(
        select id, parent_id, hidden, name from ($n) order by length\(name\) desc
    \), ($name) as \(
        select id, hidden, name from ($n)_1 group by id
    \)"
}

export def dbg [switch content -t:string] {
    if $switch {
        print $"(ansi grey)($t)│($content)(ansi reset)"
    }
}

export def get-config [kind] {
    sqlx $"select * from kind where name = (Q $kind)" | first
}

export def 'to title' [config] {
    $in | str replace ($config.comment) ''
}

export def 'from title' [config] {
    $"($config.comment)($in)"
}


export def entity [
    cfg
    --title:string
    --kind: string
    --edit
    --created
] {
    let o = $in
    let now = date now | fmt-date
    let e = if $edit {
        let l = [($title | from title $cfg) $o]
        | str join (char newline)
        | block-edit $"scratch-XXX.($kind)" ($cfg | update pos {|x| $x.pos + 1 })
        | lines
        let title = $l | first | to title $cfg
        let body = $l | range 1.. | skip-empty-lines | str join (char newline)
        {title: $title, body: $body}
    } else {
        {title: $title, body: $o}
    }
    let created = if $created { {created: $now} } else { {} }
    {
        title: $e.title
        kind: $kind
        body: $e.body
        ...$created
        updated: $now
    }
}

