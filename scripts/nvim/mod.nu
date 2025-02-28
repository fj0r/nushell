## neovim configurations in `nvim.lua`
## or https://github.com/fj0r/nvim-taberm

# nvim tcd
export def tcd [path?: string] {
    let after = if ($path | is-empty) {
        $env.PWD
    } else {
        $path
    }
    nvim --headless --noplugin --server $env.NVIM --remote-send $"<cmd>lua HookPwdChanged\('($after)', '($env.PWD)')<cr>"
}

export-env {
    $env.config.hooks.env_change.PWD ++= [{|before, after|
        if ($env.NVIM? | is-not-empty) {
            nvim --headless --noplugin --server $env.NVIM --remote-send $"<cmd>lua HookPwdChanged\('($after)', '($before)')<cr>"
        }
    }]
}

# drop stdout to nvim buf
export def drop [] {
    if ($env.NVIM? | is-empty) {
        echo $in
    } else {
        let c = $in
        let temp = (mktemp -t nuvim.XXXXXXXX|str trim)
        $c | save -f $temp
        nvim --headless --noplugin --server $env.NVIM --remote-send $"<cmd>lua ReadTempDrop\('($temp)')<cr>"
    }
}

export def nvim-lua [...expr: string] {
    if ($env.NVIM? | is-empty) {
        echo "not found nvim instance"
    } else {
        nvim --headless --noplugin --server $env.NVIM --remote-send $'<cmd>lua vim.g.remote_expr_lua = ($expr|str join " ")<cr>'
        do -i { nvim --headless --noplugin --server $env.NVIM --remote-expr 'g:remote_expr_lua' } | complete | get stderr
    }
}

export def opwd [] {
    nvim-lua 'OppositePwd()'
}

def nve [...file:path --action(-a):string='vsplit'] {
    if ($env.NVIM? | is-empty) {
        nvim ...$file
    } else {
        let af = $file
        | each {|f|
            if ($f|str substring ..<1) in ['/', '~'] {
                $f
            } else {
                $"($env.PWD)/($f)"
            }
        }
        let action = if ($file | is-empty) { $action | str replace -r 'sp.*$' 'new' } else { $action }
        let cmd = $"<cmd>($action) ($af|str join ' ')<cr>"
        nvim --headless --noplugin --server $env.NVIM --remote-send $cmd
    }
}

export def e [...file:path] { nve ...$file -a vsplit }
export def v [...file:path] { nve ...$file -a vsplit }
export def c [...file:path] { nve ...$file -a split }
export def x [...file:path] { nve ...$file -a tabnew }

export def nvs [port: int=9999] {
    nvim --headless --listen $"0.0.0.0:($port)"
}

export def nvim-gen-service [
    name
    --ev: record = {}
    --port: int = 9999
    --host: string = 'localhost'
    --bin: string = '/usr/bin/nvim'
    --sys
    --exec
] {
    let user = whoami
    let ev = {
        HOSTNAME: (hostname)
        NVIM_FONT: nar12
        NEOVIDE_SCALE_FACTOR: 1
        SHELL: nu
        TERM: screen-256color
    }
    | merge $ev
    let host = match $host {
        local | localhost => '127.0.0.1'
        all => '0.0.0.0'
        _ => $host
    }
    let cmd = $"($bin) --listen ($host):($port) --headless +'set title titlestring=\\|($name)\\|'"
    use os/systemctl.nu *
    generate-systemd-service $"nvim:($name)" --cmd $cmd --system=$sys --environment $ev --user $user --exec=$exec
    # ~/.config/systemd/user/
}

def cmpl-nvc [] {
    let history = [$nu.cache-dir nvim_history.sqlite] | path join
    let opts = open $history
    | query db 'select cmd, count from nvim_remote_history order by count desc limit 9;'
    | rename value description
    if not ($env.HOME in ($opts | get value)) {[$env.HOME]} else {[]}
    | append $opts
}

export def nvc [
    args: string@cmpl-nvc
    --gui(-g)
    --verbose(-v)
] {
    let history = [$nu.cache-dir nvim_history.sqlite] | path join
    if not ($history | path exists) {
        "create table if not exists nvim_remote_history (
            cmd text primary key,
            count int default 1,
            recent datetime default (datetime('now', 'localtime'))
        );" | sqlite3 $history
    }
    $"insert into nvim_remote_history\(cmd\) values \('($args)'\)
    on conflict\(cmd\) do
    update set count = count + 1,
               recent = datetime\('now', 'localtime'\);"
    | sqlite3 $history
    mut cmd = []
    if $args =~ ':[0-9]+$' {
        mut addr = ''
        if ($args | str starts-with ':') {
            $addr = $"localhost($args)"
        } else {
            $addr = $args
        }
        $cmd = [--server $addr -- $"+\"set title titlestring=($addr)\""]
    } else if $args == ':' {
        $cmd = [$"+\"set title titlestring=world\""]
    } else {
        $cmd = [$"+\"set title titlestring=($args)\"" -- $args]
    }
    if $verbose {
        print ($cmd | str join ' ')
    }
    if $gui {
        let gs = {
            neovide: [--maximized --frame=none --vsync --fork]
        }
        for g in ($gs | transpose prog args) {
            if (which $g.prog | is-not-empty) {
                ^$g.prog ...$g.args ...$cmd
                break
            }
        }
    } else {
        nvim --remote-ui ...$cmd
    }
}