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

export def v [...file: string] {
    if ($file|is-empty) {
        nvim
    } else {
        edit vsplit $file
    }
}

export def t [...file: string] {
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
