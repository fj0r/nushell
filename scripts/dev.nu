export def rust-labs [
    ...args
    --nightly(-n)
    --dir(-d) = 'world/rust-labs'
] {
    let img = if $nightly {
        'xy:r9'
    } else {
        'xy:rust'
    }
    let pub_key = open ($env.HOME)/.ssh/id_ed25519.pub | split row ' ' | get 1
    let host_key = 'AAAAC3NzaC1lZDI1NTE5AAAAQNX1odF2vYCSKM1jjij7nxZgikenc2NmzPn+60QIuVBJctmdoUdXGLWexsg4QfyJkwdA9igQEHPzUoBxbSvr15c='
    mut ags = [
        -i -t
        --name rust-labs
        --device /dev/fuse --privileged
        -v ($env.HOME)/($dir):/home/master/rust-labs
        --user 1000
        -e ed25519_master=($pub_key)
        -e SSH_HOSTKEY_ED25519=($host_key)
        -p 2233:22
    ]
    $ags ++= [$img]
    $ags ++= $args
    ^$env.CNTRCTL run ...$ags
}
