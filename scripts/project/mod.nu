export use utils.nu *
export use git-hooks.nu *

export-env {
    use git-hooks.nu *
    if 'config' in $env {
        let load_msg = $"print '(ansi default_italic)(ansi grey)`__.nu` as overlay (ansi default_bold)__(ansi reset)'"

        $env.config.hooks.env_change = $env.config.hooks.env_change
        | upsert 'PWD' {|x| $x.PWD? | default [] }

        $env.config.hooks.env_change.PWD ++= [
            {
                condition: {|_, after| '__' in (overlay list) }
                code: ([
                    $"overlay hide __ --keep-env [ PWD OLDPWD ]"
                    $"print '(ansi default_italic)(ansi grey)unload overlay (ansi default_bold)__(ansi reset)'"
                ] | str join (char newline))
            }
            {
                condition: {|_, after| $after | path join __.nu | path exists }
                code: ([
                    $load_msg
                    $"overlay use -r __.nu as __ -p"
                    $"cd $after"
                    $"direnv __"
                ] | str join (char newline))
            }
        ]

        let cmd = [
            $"overlay use -r __.nu as __ -p"
            $"direnv __"
            $load_msg
        ]
        | str join '; '

        $env.config.keybindings ++= [
            {
                modifier: control_alt
                keycode: char_o
                mode: [emacs, vi_normal, vi_insert]
                event: [
                    { send: ExecuteHostCommand, cmd: $cmd }
                ]
            }
        ]
    } else {
        # nu -c 'batch mode'
    }
}

