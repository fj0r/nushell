def pwd_overlay [] {
    [
        {
            condition: {|before, after| ($before != $after) and ('cwd' in (overlay list)) }
            code: "
                overlay hide cwd --keep-env [ PWD ]
            "
        }
        {
            condition: {|before, after| ($before != $after) and ($after | path join .nu | path exists) }
            code: "
                overlay use -r ./.nu as cwd
                # :XXX: workaround for `overlay use -r .nu --keep-env [ PWD ]`
                #if not (($before | is-empty) or ($before | path join .nu | path exists)) {
                #    cd $after
                #}
            "
        }
    ]
}

export-env {
    let-env config = ( $env.config | upsert hooks.env_change.PWD { |config|
        let o = ($config | get -i hooks.env_change.PWD)
        let val = (pwd_overlay)
        if $o == $nothing {
            $val
        } else {
            $o | append $val
        }
    })
}
