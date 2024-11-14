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
    --runner: string
] {
    let stdin = $in
    let cmd = $ctx.cmd
    let dir = $ctx.dir?
    let entry = $ctx.entry
    let args = if ($ctx.args? | is-empty) { '' } else { $ctx.args | str join ' ' }
    let opt = $ctx.opt? | default {}

    if ($dir | is-not-empty) { cd $dir }

    let i = [$dir $stdin_file] | path join
    $stdin | default '' | save -f $i

    match $runner {
        docker | container => {
            let vols = $opt.volumes? | default {}
            | items {|k, v| [-v $"($k):($v)"] } | flatten
            let ports = $opt.ports? | default {}
            | items {|k, v| [-p $"($k):($v)"] } | flatten
            let envs = $opt.environment? | default {}
            | items {|k, v| [-e $"($k):($v)"] } | flatten
            let entrypoint = if ('entrypoint' in $opt) { [--entrypoint $opt.entrypoint] } else { [] }
            let wd = $opt.workdir? | default '/app'
            let entry = [$wd $entry] | path join
            let cmd = $cmd | render {_: $entry, stdin: $i, args: $args, ...$opt}

            let container_name = $dir | path basename
            let args = [
                --name $container_name --rm -it
                --workdir $wd
                -v $"($dir):($wd)"
                ...$vols
                ...$ports
                ...$envs
                ...$entrypoint
                $opt.image
                $cmd
            ] | filter {|x| $x | is-not-empty }

            do -i { ^$env.CONTCTL run ...$args }
        }
        _ => {
            let cmd = $cmd | render {_: $entry, stdin: $i, args: $args, ...$opt}
            do -i {
                nu -c $"($cmd) | to json" | from json
            }
        }
    }
}


export def performance [
    config
    stdin?=''
    --context: record
    --preset: string
    --args:list<string>
] {
    let o = $in
    match $config.runner {
        'file' | 'dir' | 'docker' | 'container' => {
            let opt = sqlx $"select data from kind_preset where kind = (Q $config.name) and name = (Q $preset)"
            | get -i 0.data | default '{}' | from yaml

            let f = if ($context | is-empty) {
                $o | mktmpdir $'scratch-XXXXXX' $config.entry --kind $config.name
            } else {
                # print $"(ansi blue)Runner[($config.runner)] use the file created earlier(ansi reset)"
                $context
            }

            let r = $stdin | run-cmd --runner $config.runner {
                cmd: $config.cmd
                args: $args
                entry: $f.entry
                dir: $f.dir
                opt: $opt
            }

            rm -rf $f.dir
            $r
        }
        'data' => {
            let f = if ($context | is-empty) {
                $o | mktmpdir $'scratch-XXXXXX' $config.entry --kind $config.name
            } else {
                # print $"(ansi blue)Runner[($config.runner)] use the file created earlier(ansi reset)"
                $context
            }
            open --raw $f.file | lines | range 1.. | str join (char newline)
            | collect | save -f $f.file
            match $config.name {
                yaml | nuon | json | toml | csv | tsv | xml => {
                    open $f.file
                }
                lines => {
                    open $f.file | lines
                }
                jsonl => {
                    open $f.file | from json -o
                }
                _ => {
                    $o
                }
            }
        }
        _ => {
            let f = if ($context | is-empty) {
                $o | mktmpdir $'scratch-XXXXXX' $config.entry --kind $config.name
            } else {
                # print $"(ansi blue)Runner[($config.runner)] use the file created earlier(ansi reset)"
                $context
            }

            let r = open $f.file
            | lines
            | range 1..
            | skip-empty-lines
            | str join (char newline)

            rm -rf $f.dir
            $r
        }
    }
}

export def cmpl-kind [] {
    sqlx $"select name from kind" | get name
}

export def cmpl-kind-preset [ctx] {
    if (scope commands | where name == 'argx parse' | is-empty) {
        sqlx $"select name as value, kind as description from kind_preset"
    } else {
        let k = $ctx | argx parse
        let k1 = $k | get -i opt.kind
        let k2 = $k | get -i pos.kind
        let k = ($k1 | default $k2)
        sqlx $"select name as value, kind as description from kind_preset where kind = (Q $k)"
    }
}
