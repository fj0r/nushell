def dynamic_load [] {
    [
        {
            condition: {|before, after| (not ('dynamic-load' in (overlay list))) and ('~/.nu' | path exists) }
            code: "overlay use ~/.nu as dynamic-load"
        }
    ]
}

export-env {
    let-env config = ( $env.config | upsert hooks.env_change.PWD { |config|
        let o = ($config | get -i hooks.env_change.PWD)
        let val = (dynamic_load)
        if $o == $nothing {
            $val
        } else {
            $o | append $val
        }
    })
}
