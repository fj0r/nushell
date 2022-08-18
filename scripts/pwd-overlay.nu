let pwd_overlay = [
    {
        condition: {|before, after| ($before != $after) and ('pwdoverlay' in (overlay list)) }
        code: "overlay remove pwdoverlay --keep-env [ PWD ]"
    }
    {
        condition: {|before, after| ($before != $after) and ($after | path join .nu | path exists) }
        # :XXX: `cd $after` workaround for `overlay add .nu --keep-env [ PWD ]`
        code: "
            overlay add .nu as pwdoverlay
            cd $after
        "
    }
]        

let-env config = ($env.config | upsert hooks.env_change.PWD $pwd_overlay)
