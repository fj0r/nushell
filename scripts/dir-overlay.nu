let dir-overlay = [
    {
        condition: {|_, after|($after | path join oy.nu | path exists) }
        code: "overlay add oy.nu"
    }
    {
        condition: {|before, after| ('oy' in (overlay list)) }
        code: "overlay remove oy --keep-env [ PWD ]"
    }
]        

let-env config = ($env.config | upsert hooks.env_change.PWD $dir-overlay)
