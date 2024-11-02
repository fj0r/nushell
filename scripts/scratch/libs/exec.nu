def remove-file [...fs] {
    for f in $fs {
        if ($f | is-not-empty) {
            rm -f $f
        }
    }
}

export def performance [
    config
    stdin?=''
    --preset: string
] {
    let f = $in | maketemp $'scratch-XXX.($config.ext)'
    let i = $stdin | maketemp $'scratch-XXX.stdin'
    let opt = if $config.runner in ['file', 'dir'] {
        let q = $"select yaml from kind_preset where kind = (Q $config.name) and name = (Q $preset)"
        sqlx $q | get -i 0.yaml | default '{}' | from yaml
    } else {
        {}
    }
    match $config.runner {
        'file' => {
            let cmd = $config.cmd | render {_: $f, stdin: $i, ...$opt}
            nu -m light -c $cmd
            remove-file $f $i
        }
        'dir' => {
            remove-file $f $i
        }
        _ => {
            let o = open $f
            remove-file $f $i
            $o
        }
    }
}

export def cmpl-kind [] {
    sqlx $"select name from kind" | get name
}

export def cmpl-kind-preset [] {
    sqlx $"select name as value, kind as description from kind_preset"
}
