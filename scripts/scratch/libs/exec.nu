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

export def run-cmd [
    ctx
    --stdin-file: string = '.stdin'
    --transform: closure
] {
    let stdin = $in
    let cmd = $ctx.cmd
    let dir = $ctx.dir?
    let entry = $ctx.entry
    let opt = $ctx.opt? | default {}

    if ($dir | is-not-empty) { cd $dir }

    let i = [$dir $stdin_file] | path join
    $stdin | default '' | save -f $i
    let cmd = $cmd | render {_: $entry, stdin: $i, ...$opt}
    do -i {
        let cmd = if ($transform | is-empty) { $cmd } else { $"($cmd) | do (view source $transform)" }
        nu -m light -c $cmd
    }
}

export def performance [
    config
    stdin?=''
    --tmpfile: record
    --preset: string
    --transform(-t): closure
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

            $stdin | run-cmd --transform $transform {
                cmd: $config.cmd
                entry: $f.entry
                dir: $f.dir
                opt: $opt
            }

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


            let vols = $opt.volumes? | default {}
            | items {|k, v| [-v $"($k):($v)"] } | flatten
            let ports = $opt.ports? | default {}
            | items {|k, v| [-p $"($k):($v)"] } | flatten
            let envs = $opt.environment? | default {}
            | items {|k, v| [-e $"($k):($v)"] } | flatten
            let entrypoint = if ('entrypoint' in $opt) { [--entrypoint $opt.entrypoint] } else { [] }
            let wd = $opt.workdir? | default '/app'
            let entry = [$wd $f.entry] | path join
            let cmd = $config.cmd | render {_: $entry, stdin: $i, ...$opt}

            let container_name = $f.dir | path basename
            let args = [
                --name $container_name --rm -it
                --workdir $wd
                -v $"($f.dir):($wd)"
                ...$vols
                ...$ports
                ...$envs
                ...$entrypoint
                $opt.image
                $cmd
            ] | filter {|x| $x | is-not-empty }
            ^$env.CONTCTL run ...$args
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
