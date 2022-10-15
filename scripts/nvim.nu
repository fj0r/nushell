def nvim_tcd [] {
    [
        {|before, after|
            if 'NVIM' in (env).name {
                nvim --headless --noplugin --server $env.NVIM --remote-send $"<cmd>lua HookPwdChanged\('($after)', '($before)')<cr>"
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
        edit vsplit $file
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
        let c = $in
        let temp = (mktemp -t nuvim.XXXXXXXX|str trim)
        $c | save $temp
        nvim --headless --noplugin --server $env.NVIM --remote-send $'<cmd>vnew|read ($temp)<cr>'
        nvim --headless --noplugin --server $env.NVIM --remote-send $'<cmd>silent !rm -f ($temp)<cr>'
    } else {
        echo $in
    }
}

export def nvim_lua [...expr: string] {
    if 'NVIM' in (env).name {
        nvim --headless --noplugin --server $env.NVIM --remote-send $'<cmd>lua vim.g.remote_expr_lua = ($expr|str join " ")<cr>'
        do -i { nvim --headless --noplugin --server $env.NVIM --remote-expr 'g:remote_expr_lua' } | complete | get stderr
    } else {
        echo "not found nvim instance"
    }
}

export def opwd [] {
    nvim_lua 'OppositePwd()'
}
