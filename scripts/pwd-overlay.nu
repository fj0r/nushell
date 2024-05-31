def pwd_overlay [] {
    [
        {
            condition: {|_, after| 'o' in (overlay list) }
            code: "
                overlay hide o --keep-env [ PWD ]
            "
        }
        {
            condition: {|_, after| $after | path join overlay.nu | path exists }
            code: "
                print $'(ansi default_underline)(ansi default_bold)overlay.nu(ansi reset) (ansi green_italic)detected(ansi reset)...'
                print $'(ansi yellow_italic)activating(ansi reset) (ansi default_underline)(ansi default_bold)overlay.nu(ansi reset) as `(ansi default_dimmed)(ansi default_italic)o(ansi reset)`'
                overlay use -r overlay.nu as o -p
                cd $after
            "
        }
    ]
}

export-env {
    $env.config = ( $env.config | upsert hooks.env_change.PWD { |config|
        let o = ($config | get -i hooks.env_change.PWD)
        let val = (pwd_overlay)
        if $o == null {
            $val
        } else {
            $o | append $val
        }
    })
}
