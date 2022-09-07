export def "zjl" [] {
    zellij list-sessions
    | lines
    | each {|x| $"($x) -"}
    | parse -r "(?P<name>[a-z\\-]+) +(?P<current>.*)"
    | each {|x| $x | update current ( $x.current | str contains 'current' ) }
}

def "nu-complete zjsb" [] {
    zjl | where not current | get name
}

def "nu-complete zjs" [] {
    zjl | get name
}

export def zja [name: string@"nu-complete zjsb"] {
    zellij attach $name
}

export def zjk [name: string@"nu-complete zjs"] {
    zellij kill-session $name
}

export alias zjka = zellij kill-all-sessions

export alias zj = zellij -l compact
