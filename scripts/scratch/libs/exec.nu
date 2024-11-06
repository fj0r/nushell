export def wait-value [action -i: duration = 1sec  -t: string='waiting'] {
    mut time = 0
    loop {
        print -e $"(ansi light_gray)($t) (ansi light_gray_italic)($i * $time)(ansi reset)"
        let c = do --ignore-errors $action
        if ($c) { break }
        sleep $i
        $time = $time + 1
    }
}

export def performance [
    config
    stdin?=''
    --tmpfile: record
    --preset: string
] {
    let o = $in
    let opt = if $config.runner in ['file', 'dir', 'docker', 'container'] {
        let q = $"select data from kind_preset where kind = (Q $config.name) and name = (Q $preset)"
        sqlx $q | get -i 0.data | default '{}' | from yaml
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
        'docker' | 'container' => {
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

            let vols = $opt.volumes? | default {}
            | items {|k, v| [-v $"($k):($v)"] } | flatten
            let ports = $opt.ports? | default {}
            | items {|k, v| [-p $"($k):($v)"] } | flatten
            let envs = $opt.environment? | default {}
            | items {|k, v| [-e $"($k):($v)"] } | flatten

            let container_name = $f.dir | path basename
            let args = [
                --name $container_name -d
                -v $"($f.dir):($opt.workdir? | default '/app')"
                ...$vols
                ...$ports
                ...$envs
                $opt.image
                $opt.command?
            ] | filter {|x| $x | is-not-empty }
            ^$env.CONTCTL run ...$args

            wait-value -t $"wait container ($container_name)" {
                $container_name in (container-list | get name)
            }
            ^$env.CONTCTL exec -it $container_name $cmd
            ^$env.CONTCTL rm -f $container_name
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
