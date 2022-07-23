let dir-overlay = [
    {
        condition: {|before, after| ($before != $after) and ('.nu' in (overlay list)) }
        code: "overlay remove .nu --keep-env [ PWD ]"
    }
    {
        condition: {|before, after| ($before != $after) and ($after | path join .nu | path exists) }
        # :XXX: `overlay add .nu` as module
        code: "overlay add ./.nu"
    }
]        

let-env config = ($env.config | upsert hooks.env_change.PWD $dir-overlay)
