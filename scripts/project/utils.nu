export def 'scope project' [] {
    scope modules | where name == '__' | get -i 0
}

def 'cmpl-cmd' [] {
    let p = scope project
    [...$p.commands.name ...$p.aliases.name]
}

def 'cmd exists' [] {
    let o = $in
    scope commands | where name == $o | is-not-empty
}

# overlay use -r __.nu as __ -p
export def --wrapped 'watch __' [...cmd:string@cmpl-cmd] {
    watch-modify -c -g '__.nu' {
        [
            'use direnv'
            'direnv __'
            'overlay use -r __.nu as __ -p'
            $'__ ($cmd |str join " ")'
        ]
        | str join (char newline)
        | nu -c $in
    }
}

export def 'watch-modify' [
    --clear(-c)
    --path(-p):string='.'
    --glob(-g):string='*'
    action
] {
    do $action '' '' ''
    watch $path -g $glob -q {|op, path, new_path|
        if $op in ['Write'] {
            if $clear { ansi cls }
            do $action $op $path $new_path
            if not $clear { print $"(char newline)(ansi grey)------(ansi reset)(char newline)" }
        }
    }
}

export def --env direnv [mod?:string="__"] {
    let _ = if ('.env' | path exists) {
        open .env
        | lines
        | parse -r '(?<k>.+?)\\s*=\\s*(?<v>.+)'
        | reduce -f {} {|x, acc| $acc | upsert $x.k $x.v}
    }
    | default {}

    [yaml, toml, nuon]
    | reduce -f {} {|i,a|
        let f = $'($mod).($i)'
        if ($f | path exists) { $a | merge (open $f) } else { $a }
    }
    | merge $_
    | load-env
}

