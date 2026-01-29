export-env {
    $env.NIRI_SOCKET = glob /run/user/(id -u)/niri*sock | first
}


def cmpl-cmd [context] {
    use parser/indent.nu parse-indent
    niri msg --json out+err>| lines | get 1 | from nuon
}

export def --wrapped nmsg [cmd: string@cmpl-cmd, ...args] {
    niri msg $cmd ...$args
}

def cmpl-actions [context] {
    use parser/indent.nu parse-indent
    use argx
    let c = $context | argx parse
    niri msg action out+err>| lines
    | parse-indent
    | get 'Actions:'
    | items {|k, v| {value: $k, description: ($v | columns | first)} }
}

export def --wrapped nact [...args: string@cmpl-actions] {
    niri msg action ...$args
}
