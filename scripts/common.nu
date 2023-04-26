export alias d = podman
export alias k = kubectl
export alias r = rg
export alias s = shells
export alias ll = ls -l
export alias la = ls -a
export alias lla = ls -al
export alias l = tail -f

def "nu-complete ps" [] {
    ps -l | each {|x| { value: $"($x.pid)", description: $x.command } }
}

# after { do something ... } <pid>
export def after [action, pid: string@"nu-complete ps"] {
    do -i { tail --pid $pid -f /dev/null }
    do $action
}

