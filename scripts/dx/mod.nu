export def sandbox [
    ...args
    --image: string
    --name: string
    --dir(-d): path
    --target: path
    --port(-p) = 12222
    --sudoer = 'wheel'
    --server(-s)
] {
    let pub_key = open ($env.HOME)/.ssh/id_ed25519.pub | split row ' ' | get 1
    let host_key = 'AAAAC3NzaC1lZDI1NTE5AAAAQNX1odF2vYCSKM1jjij7nxZgikenc2NmzPn+60QIuVBJctmdoUdXGLWexsg4QfyJkwdA9igQEHPzUoBxbSvr15c='
    let port = port $port
    let user = 'master'
    mut ags = [
        --name $name
        --device /dev/fuse --privileged
        -v ($dir | path expand):($target)
        --user 1000
        -e ed25519_($user)=($pub_key)
        -e SSH_HOSTKEY_ED25519=($host_key)
        -e SSH_SUDO_GROUP=($sudoer)
        -p ($port):22
    ]
    if $server {
        $ags ++= [-i -t]
    } else {
        $ags ++= [-d -t]
    }

    $ags ++= [$image]
    $ags ++= $args
    ^$env.CNTRCTL run ...$ags
    if not $server {
        ^zeditor $"zed://ssh/($user)@localhost:($port)/home/($user)/rust-lab"
    }
}

export def rust-labs [
    ...args
    --nightly(-n)
    --dir(-d) = 'world/rust-labs'
    --port(-p) = 12222
    --server(-s)
] {
    let img = if $nightly {
        'ghcr.io/fj0r/xy:r9'
    } else {
        'ghcr.io/fj0r/xy:rust'
    }
    (
        sandbox ...$args
        --name rust-labs
        --image $img
        --dir ($env.HOME)/($dir)
        --port $port
        --server=$server
        --target '/home/master/rust-labs'
    )
}
