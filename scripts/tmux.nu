module tmux {
    export alias tl = (tmux list-sessions | parse -r "(?P<name>.+): (?P<win>[0-9]+) windows (?P<date>.+)")

    def "nu-complete tln" [] {
        tmux list-sessions | parse -r "(?P<name>.+): " | get name
    }
    
    export def t [name?: string@"nu-complete tln"] {
        if ($name) in (tl | get name) {
            tmux attach -t $name
        } else {
            let name = $"(whoami|str trim)@(hostname|str trim)[($name)]"
            tmux new -s $name
        }
    }
}

use tmux *


alias zj = zellij -l compact
