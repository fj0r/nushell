use complete.nu *

export def --wrapped quadlet-create [
    --name: string
    --debug(-x)
    --appimage
    --netadmin
    --user(-u): string
    --proxy: string@cmpl-docker-run-proxy      # proxy
    --ssh(-s): string@cmpl-docker-run-sshkey   # specify ssh key
    --sshuser: string=root                     # default root
    --mnt(-m): string@cmpl-docker-run-vol      # mnt
    --vols(-v): record                         # { host: container }
    --ports(-p): record                        # { 8080: 80 }
    --envs(-e): record                         # { FOO: BAR }
    --daemon(-d)
    --join(-j): string@cmpl-docker-containers  # join
    --network: string@cmpl-docker-network      # network
    --workdir(-w): string                      # workdir
    --entrypoint: string                       # entrypoint
    --exec
    --with-x
    --nvidia:int
    --privileged(-P)
    --options: list<string>
    --require(-r): string
    --system
    image: string@cmpl-docker-images           # image
    ...cmd                                     # command args
] {
    mut opts = []

    if ($envs | is-not-empty) {
        $opts ++= $envs | items {|k, v| [Environment=($k)=($v)] } | flatten
    }

    if ($vols | is-not-empty) {
        $opts ++= $vols | items {|k, v| [Volume=(host-path $k):($v)]} | flatten
    }

    if ($ports | is-not-empty) {
        for i in ($ports | transpose k v) {
            mut is_udp = false
            let p = if ($i.k | str substring (-4).. | str downcase) == '/udp' {
                $is_udp = true
                $i.k | str substring 0..-5 | into int
            } else {
                $i.k | into int
            }
            let k = port $p
            let v = if $is_udp { ($i.v)/udp } else { $"($i.v)" }
            $opts ++= [PublishPort=($k):($v)]
        }
    }

    if $debug {
        $opts ++= [--cap-add=SYS_ADMIN --cap-add=SYS_PTRACE --security-opt seccomp=unconfined] | str join ' ' | [$"PodmanArgs=($in)"]
    }

    if ($cmd | is-not-empty) {
        $opts ++= [$"Exec=($cmd | str join ' ')"]
    }

    if ($entrypoint | is-not-empty) {
        $opts ++= [$"Entrypoint=($entrypoint | str join ' ')"]
    }


    let opts = $opts

    let name = if ($name | is-empty) {
        let img = $image | split row '/' | last | str replace ':' '-'
        let now = date now | format date %m%d%H%M
        ($img)_($now)
    } else {
        let c = container-list | where name == $name
        if ($c | is-not-empty) {
            container-remove $name
        }
        $name
    }

    let req = if ($require | is-not-empty) {
        {
            Requires: $"($require).service"
            After: $"($require).service"
        }
    } else {
        {
            After: local-fs.target
        }
    }

    let t = {
        Unit: {
            Description: $"The ($name) container"
            ...$req
        }
        Container: {
            ContainerName: $name
            Image: $image
        }
        Service: {
            Restart: always
        }
        Install: {
            WantedBy: 'multi-user.target default.target'
        }
    }
    | transpose k v
    | each {|i|
        mut r = [$"[($i.k)]"]
        for j in ($i.v | transpose k v) {
            $r ++= [($j.k)=($j.v)]
        }
        if $i.k == Container {
            $r ++= $opts
        }
        $r | str join "\n"
    }
    | str join "\n\n"

    if $exec {
        let s = $"($name).container"
        if $system {
            let p = [/etc/containers/systemd $s] | path join
            $t | save -f $p
            sudo systemctl disable --now $name
            sudo systemctl daemon-reload
            sudo systemctl enable --now $name
        } else {
            let p = [$env.HOME .config container systemd $s] | path join
            $t | save -f $p
            systemctl disable --user --now $name
            systemctl enable --user --now $name
        }
    } else {
        $t
    }
}
