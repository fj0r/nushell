let dir-overlay = { |before, after|
    let o = $"($after)/overlay.nu"
    if ($o | path exists) {
        #TODO: unimplement
        #overlay add overlay.nu
    }
}

let-env config = ($env.config
                 | upsert hooks.env_change.PWD ($env.config.hooks.env_change.PWD | append $dir-overlay)
                 )
