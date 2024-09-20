def pwd_overlay [] {
    [
        {
            condition: {|_, after| 'un' in (overlay list) }
            code: "
                overlay hide un --keep-env [ PWD ]
            "
        }
        {
            condition: {|_, after| $after | path join un.nu | path exists }
            code: "
                print $'(ansi default_underline)(ansi default_bold)un.nu(ansi reset) (ansi green_italic)detected(ansi reset)...'
                print $'(ansi yellow_italic)activating(ansi reset) (ansi default_underline)(ansi default_bold)un.nu(ansi reset) as `(ansi default_dimmed)(ansi default_italic)un(ansi reset)`'
                overlay use -r un.nu as un -p
                cd $after
            "
        }
    ]
}

export-env {
    $env.config.hooks.env_change.PWD ++= pwd_overlay
}
