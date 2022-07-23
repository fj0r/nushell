let dir-overlay = [
    {
        condition: {|before, after| ('x' in (overlay list)) }
        code: "overlay remove x --keep-env [ PWD ]"
    }
    {
        condition: {|_, after|($after | path join x.nu | path exists) }
        code: "overlay add x.nu"
    }
]        

let-env config = ($env.config | upsert hooks.env_change.PWD $dir-overlay)
