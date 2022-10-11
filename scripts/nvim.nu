def nvim_tcd [] {
    [
        {|before, after|
            if 'NVIM' in (env).name {
                nvim --headless --noplugin --server $env.NVIM --remote-send $"<cmd>silent tcd! ($after)<cr>"
            }
        }
    ]
}

export-env {
    let-env config = ( $env.config | upsert hooks.env_change.PWD { |config|
        let o = ($config | get -i hooks.env_change.PWD)
        let val = (nvim_tcd)
        if $o == $nothing {
            $val
        } else {
            $o | append $val
        }
    })
}

def edit [action file] {
    if 'NVIM' in (env).name {
        let af = ($file | each {|f|
            if ($f|str substring ',1') in ['/', '~'] {
                $f
            } else {
                $"($env.PWD)/($f)"
            }
        })
        let cmd = $"<cmd>($action) ($af|str join ' ')<cr>"
        nvim --headless --noplugin --server $env.NVIM --remote-send $cmd
    } else {
        nvim $file
    }
}

export def e [...file: string] {
    if ($file|is-empty) {
        nvim
    } else {
        edit split $file
    }
}

export def c [...file: string] {
    if ($file|is-empty) {
        nvim
    } else {
        edit split $file
    }
}

export def v [...file: string] {
    if ($file|is-empty) {
        nvim
    } else {
        edit vsplit $file
    }
}

export def x [...file: string] {
    if ($file|is-empty) {
        nvim
    } else {
        edit tabnew $file
    }
}

export def drop [] {
    if 'NVIM' in (env).name {
        # TODO:
        let b = (nvim --headless --noplugin --server $env.NVIM --remote-expr 'new')
        nvim --headless --noplugin --server $env.NVIM --remote-send $in
    } else {
        echo $in
    }
}
