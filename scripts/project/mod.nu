export use utils.nu *

export-env {
    if 'config' in $env {
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
                    $"direnv __"
                ] | str join (char newline))
            }
        ]
    } else {
        # nu -c
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
