export-env {
    $env.NIRI_SOCKET = glob /run/user/(id -u)/niri*sock | first
    $env.NIRI_STARTUP = [
        [okular alacritty]
        [alacritty qutebrowser neovide]
        [alacritty]
    ]
}
export def 'niri startup' [] {
    for i in $env.NIRI_STARTUP {
        for j in $i {
            niri msg action spawn -- $j
        }
        niri msg action focus-workspace-down
    }
}
