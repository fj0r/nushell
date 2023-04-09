def "nu-complete zl" [] {
    zellij list-sessions
    | lines
    | filter {|x| not ($x | str contains '(current)') }
    | each {|x| { value: $x } }
}

export def za [session: string@"nu-complete zl"] {
    zellij attach $session
}
