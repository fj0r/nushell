def pwd_overlay [] {
    [
        {
            condition: {|_, after| 'only' in (overlay list) }
            code: "
                overlay hide only --keep-env [ PWD ]
            "
        }
        {
            condition: {|_, after| $after | path join only.nu | path exists }
            code: "
                print $'(ansi default_underline)(ansi default_bold)overlay.nu(ansi reset) (ansi green_italic)detected(ansi reset)...'
                print $'(ansi yellow_italic)activating(ansi reset) (ansi default_underline)(ansi default_bold)overlay.nu(ansi reset) as `(ansi default_dimmed)(ansi default_italic)only(ansi reset)`'
                overlay use -r only.nu as only -p
                cd $after
            "
        }
    ]
}

export-env {
    $env.config.hooks.env_change.PWD ++= pwd_overlay
}
