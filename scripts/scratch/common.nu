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

export def upsert-kind [--delete --action: closure] {
    $in | table-upsert --delete=$delete --action $action {
        default: {
            name: 'md'
            entry: null
            comment: "# "
            runner: 'file'
            cmd: 'open {}'
        }
        table: kind
        pk: [name]
        filter: {}
    }
}

export def upsert-kind-preset [--delete --action: closure] {
    $in | table-upsert --delete=$delete --action $action {
        default: {
            kind: 'sqlite'
            name: ''
            data: ""
        }
        table: kind_preset
        pk: [kind, name]
        filter: {
            out: {
                data: {|x| $x | to yaml }
            }
            in: {
                data: {|x| $x | from yaml }
            }
        }
    }
}

export def dbg [switch content -t:string] {
    if $switch {
        print $"(ansi grey)($t)│($content)(ansi reset)"
    }
}

export def get-config [kind --preset:string] {
    if ($preset | is-empty) {
        sqlx $"select * from kind where name = (Q $kind)" | first
    } else {
        sqlx $"select k.name, k.entry, k.comment, k.runner, k.cmd, k.pos, p.name as preset, p.data
        from kind as k left join kind_preset as p on k.name = p.kind
        where k.name = (Q $kind) and p.name = (Q $preset)" | first
    }
}

def 'to title' [config] {
    $in | str replace ($config.comment) ''
}

def 'from title' [config] {
    $"($config.comment)($in)"
}


export def entity [
    cfg
    --title:string
    --batch
    --created
    --locate-body
    --perf-ctx: record
] {
    let o = $in
    let now = date now | fmt-date
    let pos = if $locate_body {
        $cfg.pos + 1
    } else {
        1
    }
    mut x = {}
    let e = if not $batch {
        let title = $title | from title $cfg
        let preset = if ($cfg.data? | is-empty) { {} } else { $cfg.data | from yaml }
        $x = $o
        | block-project-edit $"scratch-XXXXXX" $cfg.entry $pos --kind $cfg.name --title $title --created=$created --preset $preset --command $cfg.cmd --perf-ctx $perf_ctx
        let l = $x
        | get content
        | lines
        let title = $l | first | to title $cfg
        let body = $l | range 1.. | skip-empty-lines | str join (char newline)
        {title: $title, body: $body}
    } else {
        {title: $title, body: $o}
    }
    let created = if $created { {created: $now} } else { {} }
    {
        context: $x
        value: {
            title: $e.title
            kind: $cfg.name
            body: $e.body
            ...$created
            updated: $now
        }
    }
}

export def 'uplevel done' [pid now done:bool] {
    mut p = $pid
    loop {
        if $done {
            # Check if all nodes at the current level are Done
            let all_done = (sqlx $"select count\(1\) as c from scratch
                where parent_id = ($p) and deleted = '' and done = 0"
            | get 0.c | default 0) == 0
            if $all_done {
                let r = sqlx $"update scratch set done = 1, updated = ($now) where id = ($p) returning parent_id;"
                if ($r | is-empty) {
                    break
                } else {
                    $p = $r | get 0.parent_id
                }
            } else {
                sqlx $"update scratch set done = 0, updated = ($now) where id = ($p)"
                break
            }
        } else {
            let x = sqlx $"update scratch set done = 0, updated = ($now) where id = ($p) and done = 1 returning parent_id;"
            if ($x | is-empty) {
                break
            } else {
                $p = $x | get 0.parent_id
            }
        }
    }
}

export def from-all [type] {
    let o = $in
    match $type {
        json => { $o | from json }
        jsonl => { $o | from json -o }
        yaml => { $o | from yaml }
        toml => { $o | from toml }
        nuon => { $o | from nuon }
        csv => { $o | from csv }
        tsv => { $o | from tsv }
        xml => { $o | from xml }
        lines => { $o | lines }
        _ => $o
    }
}

export def to-all [type] {
    let o = $in
    match $type {
        json => { $o | to json }
        jsonl => { $o | each { $in | to json -r } | str join (char newline) }
        yaml => { $o | to yaml }
        toml => { $o | to toml }
        nuon => { $o | to nuon }
        csv => { $o | to csv }
        tsv => { $o | to tsv }
        xml => { $o | to xml }
        lines => { $o | str join (char newline) }
        _ => $o
    }
}
