def project_overlay [] {
    [
        {
            condition: {|_, after| '__' in (overlay list) }
            code: "
                overlay hide __ --keep-env [ PWD ]
            "
        }
        {
            condition: {|_, after| $after | path join __.nu | path exists }
            code: "
                print $'(ansi default_underline)(ansi default_bold)__.nu(ansi reset) (ansi green_italic)detected(ansi reset)...'
                print $'(ansi yellow_italic)activating(ansi reset) (ansi default_underline)(ansi default_bold)__.nu(ansi reset) as `(ansi default_dimmed)(ansi default_italic)__(ansi reset)`'
                overlay use -r __.nu as __ -p
                cd $after
            "
        }
    ]
}

export-env {
    $env.config.hooks.env_change.PWD ++= project_overlay
}
