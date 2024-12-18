export def zellij-session [] {
    zellij list-sessions -n
    | lines
    | parse -r '^(?<name>[\w-]+) \[(?<time>.+)\]( \((?<status>.+)\))?'
    | select name time status
}

def cmpl-zellij-session [] {
    zellij-session
    | each {|x|
        { value: $x.name, describe: $"($x.status) -- ($x.time)" }
    }
}

export def zellij-enter [name: string@cmpl-zellij-session] {
    if $name in (zellij-session | get name) {
        zellij attach $name
    } else {
        zellij -s $name
    }
}

export def zellij-delete [name: string@cmpl-zellij-session] {
    zellij delete-session $name
}
