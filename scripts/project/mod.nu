export use utils.nu *
export use git-hooks.nu *
export use reg.nu *

export-env {
    project init-git-hooks
    if 'config' in $env {
        project init-registry

        let load_msg = $"print '(ansi default_italic)(ansi grey)`,.nu` as overlay (ansi default_bold),(ansi reset)'"

        $env.config.hooks.env_change = $env.config.hooks.env_change
        | upsert 'PWD' {|x| $x.PWD? | default [] }

        $env.config.hooks.env_change.PWD ++= [
            {
                condition: {|_, after| ',' in (overlay list | where active | get name) }
                code: ([
                    #$"hide ," # HACK: clean
                    $"overlay hide , --keep-env [ PWD OLDPWD config ]"
                    $"print '(ansi default_italic)(ansi grey)unload overlay (ansi default_bold),(ansi reset)'"
                ] | str join (char newline))
            }
            {
                condition: {|_, after| $after | path join ,.nu | path exists }
                code: ([
                    $load_msg
                    $"overlay use --reload --prefix ,.nu as ,"
                    $"direnv ,"
                    #$"project register $after --mod ,"
                ] | str join (char newline))
            }
        ]

        let cmd = [
            $"overlay use -r ,.nu as , -p"
            $"direnv ,"
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
