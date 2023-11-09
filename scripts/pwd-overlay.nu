def pwd_overlay [] {
    [
        {
            condition: {|_, after| 'cwd' in (overlay list) }
            code: "
                overlay hide cwd --keep-env [ PWD ]
            "
        }
        {
            condition: {|_, after| $after | path join ,.nu | path exists }
            code: "
                overlay use -r ,.nu as cwd
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
