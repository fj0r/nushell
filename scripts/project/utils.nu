export def 'scope project' [] {
    scope modules | where name == '%' | get -o 0
}

def 'cmpl-cmd' [] {
    let p = scope project
    [...$p.commands.name ...$p.aliases.name]
}

def 'cmd exists' [] {
    let o = $in
    scope commands | where name == $o | is-not-empty
}

# overlay use -r %.nu as % -p
export def --wrapped 'project watch' [...cmd:string@cmpl-cmd] {
    run-and-watch -c -g '%.nu' {
        [
            'use project'
            'project direnv %'
            'overlay use -r %.nu as % -p'
            $'% ($cmd |str join " ")'
        ]
        | str join (char newline)
        | nu -c $in
    }
}

export def 'run-and-watch' [
    --clear(-c)
    --path(-p):string='.'
    --glob(-g):string='*'
    action
] {
    do $action '' '' ''
    watch $path -g $glob -q
    | where operation in ['Write']
    | each {
        if $clear { ansi cls }
        do $action $in
        if not $clear { print $"(char newline)(ansi grey)------(ansi reset)(char newline)" }
    }
}

export def parse-env [] {
    $in
    | lines
    | parse -r '\s*(?<k>.+?)\s*=\s*(?<v>.+)'
    | reduce -f {} {|x, acc| $acc | upsert $x.k $x.v}
}

export def --env direnv [
    mod?:string="%"
    --env-file(-e):string='.env'
] {
    let _ = if ($env_file | path exists) {
        open $env_file | parse-env
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

# new dir and then cd
export def --env nd [
    dir
    --surrfix(-s)="--"
    --temp(-t)
] {
    let dir = if not $temp {
        $dir
    } else {
        $"($surrfix)($dir)($surrfix)" | path expand
    }
    mkdir $dir
    cd $dir
    if $temp {
        $env.config.hooks.env_change.PWD ++= [
            {
                condition: {|before, after| $before == $dir }
                code: $"rm -rf ($dir)"
            }
        ]
    }
}

export def find-project [dir] {
    for d in (
        $dir
        | path expand
        | path split
        | slice 1..
        | reduce -f ['/'] {|i, a| $a | append ([($a | last) $i] | path join) }
        | each { [$in '%.nu'] | path join }
        | reverse
    ) {
        if ($d | path exists) { return $d }
    }
    ''
}
