export-env {
    $env.config.hooks.env_change.PWD ++= [
        {
            condition: {|_, after| '__' in (overlay list) and (find-project $after | is-empty) }
            code: ([
                $"overlay hide __ --keep-env [ PWD OLDPWD ]"
                $"print '(ansi default_italic)(ansi grey)unload overlay (ansi default_bold)__(ansi reset)'"
            ] | str join (char newline))
        }
        {
            condition: {|_, after| $after | path join __.nu | path exists }
            code: ([
                $"print '(ansi default_italic)(ansi grey)`__.nu` as overlay (ansi default_bold)__(ansi reset)'"
                $"overlay use -r __.nu as __ -p"
                $"cd $after"
                (if ('direnv' | cmd exists ) { 'direnv __' })
            ] | str join (char newline))
        }
    ]
}

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

# overlay use -r __.nu as __ -p
export def --wrapped 'watch __' [...cmd:string@cmpl-cmd] {
    watch-modify -c -g '__.nu' {
        [
            ...(if ('direnv' | cmd exists) {
                [
                    'use direnv'
                    'direnv __'
                ]
            } else { [] })
            'overlay use -r __.nu as __ -p'
            $'__ ($cmd |str join " ")'
        ]
        | str join (char newline)
        | nu -c $in
    }
}

export def find-project [dir] {
    for d in (
        $dir
        | path expand
        | path split
        | range 1..
        | reduce -f ['/'] {|i, a| $a | append ([($a | last) $i] | path join) }
        | each { [$in '__.nu'] | path join }
        | reverse
    ) {
        if ($d | path exists) { return $d }
    }
    ''
}
