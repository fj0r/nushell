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
            ext: ''
            comment: "# "
            runner: 'file'
            cmd: ''
        }
        table: kind
        pk: [name]
        filter: {}
    }
}

export def add-kind-preset [] {
    $in | table-upsert {
        default: {
            kind: 'sqlite'
            name: ''
            yaml: ""
        }
        table: kind_preset
        pk: [kind, name]
        filter: {}
    }
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
    --batch
    --created
] {
    let o = $in
    let now = date now | fmt-date
    let e = if not $batch {
        let l = [($title | from title $cfg) $o]
        | str join (char newline)
        | block-edit $"scratch-XXX.($cfg.ext)" ($cfg | update pos {|x| $x.pos + 1 })
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
        kind: $cfg.name
        body: $e.body
        ...$created
        updated: $now
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
