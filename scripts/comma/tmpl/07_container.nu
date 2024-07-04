'dev'
| comma val null {
    container: [ghcr.io/project-zot/zot-linux-amd64:latest]
    id: $"($env.comma_index.wd | path parse | get stem)-test"
    user: root
}

'container up'
| comma fun {|a,s,_|
    , dev container down
    let port = $a.0
    lg level 3 {
        container: $s.dev.id
        port: $port
    } start

    mut args = [
        -p $"($port):5000"
        -v $"($_.wd)/data:/var/lib/registry"
    ]

    pp $env.docker-cli run --name $s.dev.id -d ...$args ...$s.dev.container
} {
    cmp: {|a,s|
        match ($a | length) {
            1 => [(port 5000)]
            _ => {}
        }
    }
}

'container down'
| comma fun {|a,s|
    let ns = ^$env.docker-cli ps | from ssv -a | get NAMES
    if $s.dev.id in $ns {
        lg level 2 { container: $s.dev.id } 'stop'
        pp $env.docker-cli rm -f $s.dev.id
    } else {
        lg level 3 { container: $s.dev.id } 'not running'
    }
}
