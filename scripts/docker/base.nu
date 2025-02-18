export def cmpl-docker-ns [] {
    if $env.CONTCTL == 'nerdctl' {
        ^$env.CONTCTL namespace list
        | from ssv -a
        | each {|x| { value: $x.NAME }}
    } else {
        []
    }
}


export def --env container-change-namespace [ns:string@cmpl-docker-ns] {
    $env.CONTAINER_NAMESPACE = $ns
}

export def --wrapped container [...args] {
    let o = $in
    mut ns = []
    if $env.CONTCTL in [nerdctl] {
        if ($env.CONTAINER_NAMESPACE? | is-not-empty) {
            $ns = [--namespace $env.CONTAINER_NAMESPACE]
        }
    }
    if ($o | is-empty) {
        ^$env.CONTCTL ...$ns ...$args
    } else {
        # FIXME: load
        $o | ^$env.CONTCTL ...$ns ...$args
    }
}

