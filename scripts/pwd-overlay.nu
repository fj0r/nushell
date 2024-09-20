def pwd_overlay [] {
    [
        {
            condition: {|_, after| 'orz' in (overlay list) }
            code: "
                overlay hide orz --keep-env [ PWD ]
            "
        }
        {
            condition: {|_, after| $after | path join orz.nu | path exists }
            code: "
                print $'(ansi default_underline)(ansi default_bold)overlay.nu(ansi reset) (ansi green_italic)detected(ansi reset)...'
                print $'(ansi yellow_italic)activating(ansi reset) (ansi default_underline)(ansi default_bold)overlay.nu(ansi reset) as `(ansi default_dimmed)(ansi default_italic)orz(ansi reset)`'
                overlay use -r orz.nu as orz -p
                cd $after
            "
        }
    ]
}

export-env {
    if 'PWD' not-in $env.config.hooks.env_change {
        $env.config.hooks.env_change.PWD = []
    }
    $env.config.hooks.env_change.PWD ++= pwd_overlay
}
