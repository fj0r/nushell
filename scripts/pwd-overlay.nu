let pwd_overlay = [
    {
        condition: {|before, after| ($before != $after) and ('cwd' in (overlay list)) }
        code: "overlay remove cwd --keep-env [ PWD ]"
    }
    {
        condition: {|before, after| ($before != $after) and ($after | path join .env.yaml | path exists) }
        code: "
            cat .env.yaml | from yaml | load-env
        "
    }
    {
        condition: {|before, after| ($before != $after) and ($after | path join .nu | path exists) }
        # :XXX: `cd $after` workaround for `overlay add .nu --keep-env [ PWD ]`
        code: "
            overlay add ./.nu as cwd
            cd $after
        "
    }
]        

let-env config = ($env.config | upsert hooks.env_change.PWD $pwd_overlay)
