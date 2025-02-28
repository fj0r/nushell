export def gen-nvim-service [
    name
    --ev: record = {}
    --port: int = 9999
    --host: string = '0.0.0.0'
    --bin: string = '/usr/bin/nvim'
    --sys
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
    let cmd = $"($bin) --listen ($host):($port) --headless +'set title titlestring=\\|($name)\\|'"
    gen-systemd-service $"nvim:($name)" --cmd $cmd --system=$sys --environment $ev --user $user
}

# ~/.config/systemd/user/
