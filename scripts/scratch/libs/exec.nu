export def performance [
    config
    stdin?=''
    --preset: string
] {
    let o = $in
    let opt = if $config.runner in ['file', 'dir'] {
        let q = $"select yaml from kind_preset where kind = (Q $config.name) and name = (Q $preset)"
        sqlx $q | get -i 0.yaml | default '{}' | from yaml
    } else {
        {}
    }
    match $config.runner {
        'file' => {
            let f = $o | maketemp $'scratch-XXX.($config.ext)'
            let i = $stdin | maketemp $'scratch-XXX.stdin'
            let wd = $f | path dirname
            let cmd = $config.cmd | render {_: ($f | path basename), stdin: $i, ...$opt}
            do -i {
                cd $wd
                nu -m light -c $cmd
            }
            rm -f $f
            rm -f $i
        }
        'dir' => {
            let f = mktemp -d $'scratch-XXX'
            let i = $stdin | maketemp $'scratch-XXX.stdin'
            rm -rf $f
            rm -f $i
        }
        _ => {
            let f = $o | maketemp $'scratch-XXX.($config.ext)'
            let r = open $f
            rm -f $f
            $r
        }
    }
}

export def cmpl-kind [] {
    sqlx $"select name from kind" | get name
}

export def cmpl-kind-preset [] {
    sqlx $"select name as value, kind as description from kind_preset"
}
