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
    let f = $in | maketemp $'scratch-XXX.($config.name)'
    let i = $stdin | maketemp $'scratch-XXX.stdin'
    let opt = if $config.runner in ['file', 'dir'] {
        if ($preset | is-empty) {
            print $"(ansi red)`--preset` cannot be empty when the target is executable(ansi reset)"
            return
        }
        let q = $"select yaml from kind_preset where kind = (Q $config.name) and name = (Q $preset)"
        sqlx $q | get 0.yaml | from yaml
    } else {
        {}
    }
    match $config.runner {
        'file' => {
            nu -c ($config.cmd | render {_: $f, stdin: $i, ...$opt})
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
