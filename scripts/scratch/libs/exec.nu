export def performance [
    config
    stdin?=''
    --tmpfile: record
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
        'file' | 'dir' => {
            let f = if ($tmpfile | is-empty) {
                $o | mktmpdir $'scratch-XXXXXX' $config.entry --kind $config.name
            } else {
                $tmpfile
            }
            let opwd = $env.PWD
            cd $f.dir
            let i = [$f.dir .stdin] | path join
            $stdin | save -f $i
            let cmd = $config.cmd | render {_: $f.entry, stdin: $i, ...$opt}
            do -i {
                nu -m light -c $cmd
            }
            cd $opwd
            rm -rf $f.dir
        }
        _ => {
            let f = if ($tmpfile | is-empty) {
                let ext = $config.entry| path parse | get extension
                let f = mktemp -t $'scratch-XXXXXX.($ext)'
                $o | save -f $f
                $f
            } else {
                $tmpfile
            }
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
