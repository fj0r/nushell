export alias d = podman
export alias j = just
export alias k = kubectl
export alias r = rg
export alias s = shells
export alias ll = ls -l
export alias la = ls -a
export alias lla = ls -al
export alias l = tail -f

def "nu-complete ps" [] {
    ps | each {|x| { value: $x.pid, description: $x.name } }
}

export def af [pid: string@"nu-complete ps"] {
    tail --pid $pid -f /dev/null
}
