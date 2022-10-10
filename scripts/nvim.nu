def edit [action file] {
    if 'NVIM' in (env).name {
        let cmd = $"<cmd>($action) ($file|str join ' ')<cr>"
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
