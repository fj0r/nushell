def pwd_overlay [] {
    [
        {
            condition: {|before, after| ($before != $after) and ('cwd' in (overlay list)) }
            code: "overlay hide cwd --keep-env [ PWD ]"
        }
        {
            condition: {|before, after| ($before != $after) and ($after | path join .env.yaml | path exists) }
            code: "
                cat .env.yaml | from yaml | load-env
            "
        }
        {
            condition: {|before, after| ($before != $after) and ($after | path join .nu | path exists) }
            # :XXX: `cd $after` workaround for `overlay use .nu --keep-env [ PWD ]`
            code: "
                overlay use ./.nu as cwd
                cd $after
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
