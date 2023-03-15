def "nu-complete zl" [] {
    zellij list-sessions | lines | each {|x| { value: $x } }
}

export def za [session: string@"nu-complete zl"] {
    zellij attach $session
}
