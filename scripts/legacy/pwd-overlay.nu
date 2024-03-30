def pwd_overlay [] {
    [
        {
            condition: {|_, after| ',' in (overlay list) }
            code: "
                overlay hide , --keep-env [ PWD ]
            "
        }
        {
            condition: {|_, after| $after | path join ,.nu | path exists }
            code: "
                print $'(ansi default_underline)(ansi default_bold),(ansi reset) overlay (ansi green_italic)detected(ansi reset)...'
                print $'(ansi yellow_italic)activating(ansi reset) (ansi default_underline)(ansi default_bold),(ansi reset) overlay with `(ansi default_dimmed)(ansi default_italic)overlay use -r ,.nu(ansi reset)`'
                overlay use -r ,.nu
                # :XXX: workaround for `overlay use -r ,.nu --keep-env [ PWD ]`
                #if not (($before | is-empty) or ($before | path join ,.nu | path exists)) {
                cd $after
                #}
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
