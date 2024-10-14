use complete.nu *

def --wrapped container [...flag] {
    ^$env.CONTCTL ...$flag
}

# network
export def containers-network-list [
    name?: string@cmpl-docker-network
    --subnet
] {
    if ($name | is-empty) {
        ^$env.CONTCTL network ls | from ssv -a
    } else {
        ^$env.CONTCTL network inspect $name
        | from json
        | do {
            if $subnet {
                match $env.CONTCTL {
                    podman => ($in | get subnets.0 )
                    _ => ($in | get IPAM.Config.0)
                }
            } else {
                $in
            }
        }
    }
}

export def containers-network-create [
    name: string
    --driver(-d): string@cmpl-docker-network-driver
] {
    ^$env.CONTCTL network create $name
}

export def containers-network-remove [
    network?: string@cmpl-docker-network
    --force(-f)
] {
    if ($network | is-empty) {
        ^$env.CONTCTL network prune
    } else {
        ^$env.CONTCTL network rm $network ...(if $force { [-f] } else { [] })
    }
}

# list containers
export def container-list [
    -n: string@cmpl-docker-ns
    container?: string@cmpl-docker-containers
    --all(-a)
] {
    let cli = $env.CONTCTL
    if ($container | is-empty) {
        let fmt = '{"id":"{{.ID}}", "image": "{{.Image}}", "name":"{{.Names}}", "cmd":{{.Command}}, "port":"{{.Ports}}", "status":"{{.Status}}", "created":"{{.CreatedAt}}"}'
        let fmt = if $cli == 'podman' { $fmt | str replace '{{.Command}}' '"{{.Command}}"' | str replace '{{.CreatedAt}}' '{{.Created}}' } else { $fmt }
        let all = if $all {[-a]} else {[]}
        ^$cli ps ...$all --format $fmt
            | lines
            | each {|x|
                let r = $x | from json
                let t = $r.created | into datetime
                $r | upsert created $t
            }
    } else {
        let ns = if ($n | is-empty) {[]} else {[-n $n]}
        let r = ^$cli ...$ns inspect $container
            | from json
            | get 0
        let image = $r.Image
        let img = ^$cli ...$ns inspect $image
            | from json
            | get 0
        let imgCmd = $img.Config.Cmd?
        let imgEnv = $img.Config.Env?
            | reduce -f {} {|i, a|
                let x = $i | split row '='
                $a | upsert $x.0 $x.1?
            }
        let m = $r.Mounts
            | reduce -f {} {|i, a|
                if $i.Type == 'bind' {
                    $a | upsert $i.Source? $i.Destination?
                } else { $a }
            }
        let p = $r.NetworkSettings.Ports? | default {} | transpose k v
            | reduce -f {} {|i, a| $a | upsert $i.k $"($i.v.HostIp?.0?):($i.v.HostPort?.0?)"}
        {
            name: $r.Name?
            hostname: $r.Config.Hostname?
            id: $r.Id
            status: $r.State.Status?
            image: $image
            created: ($r.Created | into datetime)
            ports: $p
            env: $imgEnv
            mounts: $m
            entrypoint: $r.Path?
            cmd: $imgCmd
            args: $r.Args
        }
    }
}

def parse-img [] {
    let n = $in | split row ':'
    let tag = $n.1? | default 'latest'
    let repo = $n.0 | split row '/'
    let image = $repo | last
    let repo = $repo | range 0..-2 | str join '/'
    {image: $image, tag: $tag, repo: $repo}
}

# list images
export def image-list [
    -n: string@cmpl-docker-ns
    image?: string@cmpl-docker-images
] {
    let ns = if ($n | is-empty) {[]} else {[-n $n]}
    if ($image | is-empty) {
        let fmt = '{"id":"{{.ID}}", "repo": "{{.Repository}}", "tag":"{{.Tag}}", "size":"{{.Size}}" "created":"{{.CreatedAt}}"}'
        ^$env.CONTCTL ...$ns images --format $fmt
            | lines
            | each {|x|
                let x = $x | from json
                let img = $x.repo | parse-img
                {
                    name: $"($x.repo):($x.tag)"
                    id: $x.id
                    created: ($x.created | into datetime)
                    size: ($x.size | into filesize)
                    repo: $img.repo
                    image: $img.image
                    tag: $x.tag
                }
            }
    } else {
        let r = ^$env.CONTCTL ...$ns inspect $image
            | from json
            | get 0
        let e = $r.Config.Env?
            | reduce -f {} {|i, a|
                let x = $i | split row '='
                $a | upsert $x.0 $x.1?
            }
        let id = if $env.CONTCTL == 'nerdctl' {
            $r.RepoDigests.0? | split row ':' | get 1 | str substring 0..<12
        } else {
            $r.Id | str substring 0..<12
        }
        {
            id: $id
            created: ($r.Created | into datetime)
            author: $r.Author
            arch: $r.Architecture
            os: $r.Os
            size: $r.Size
            labels: $r.Labels?
            user: $r.Config.User?
            env: $e
            entrypoint: $r.Config.Entrypoint?
            cmd: $r.Config.Cmd?
        }
    }
}

export def image-layer [
    -n: string@cmpl-docker-ns
    image: string@cmpl-docker-images
] {
    let ns = if ($n | is-empty) {[]} else {[-n $n]}
    ^$env.CONTCTL ...$ns inspect $image
    | from json
    | get 0.RootFS.Layers
}


# container log
export def container-log [
    container: string@cmpl-docker-containers
    -l: int = 100 # line
    -n: string@cmpl-docker-ns # namespace
] {
    let l = if $l == 0 { [] } else { [--tail $l] }
    let ns = if ($n | is-empty) {[]} else {[-n $n]}
    ^$env.CONTCTL ...$ns logs -f ...$l $container
}

export def container-log-trunc [
    container: string@cmpl-docker-containers
    -n: string@cmpl-docker-ns # namespace
] {
    if $env.CONTCTL == 'podman' {
        print -e $'(ansi yellow)podman(ansi dark_gray) isn’t supported(ansi reset)'
    } else {
        let ns = if ($n | is-empty) {[]} else {[-n $n]}
        let f = ^$env.CONTCTL ...$ns inspect --format='{{.LogPath}}' $container
        truncate -s 0 $f
    }
}

# attach container
export def --wrapped container-attach [
    container: string@cmpl-docker-containers
    -n: string@cmpl-docker-ns
    ...args
] {
    let ns = if ($n | is-empty) {[]} else {[-n $n]}
    if ($args | is-empty) {
        let cmd = [
            '/usr/local/bin/nu'
            '/bin/nu'
            '/bin/bash'
            '/bin/sh'
        ]
        | str join ' '
        | $"for sh in ($in); do if [ -e $sh ]; then exec $sh; fi; done"
        ^$env.CONTCTL ...$ns exec -it $container /bin/sh -c $cmd
    } else {
        ^$env.CONTCTL ...$ns exec -it $container ...$args
    }
}

# copy file
export def container-copy-file [
    lhs: string@cmpl-docker-cp
    rhs: string@cmpl-docker-cp
] {
    ^$env.CONTCTL cp $lhs $rhs
}

# remove container
export def container-remove [
    container: string@cmpl-docker-containers
    -n: string@cmpl-docker-ns
] {
    let ns = if ($n | is-empty) {[]} else {[-n $n]}
    let cs = ^$env.CONTCTL ...$ns ps -a | from ssv -a | get NAMES
    if $container in $cs {
        ^$env.CONTCTL ...$ns container rm -f $container
    } else {
        print -e $"(ansi grey)container (ansi yellow)($container)(ansi grey) not exist(ansi reset)"
    }
}


# history
export def container-history [image: string@cmpl-docker-images -n: string@cmpl-docker-ns] {
    let ns = if ($n | is-empty) {[]} else {[-n $n]}
    ^$env.CONTCTL ...$ns history --no-trunc $image | from ssv -a
}


# save images
export def image-save [-n: string@cmpl-docker-ns ...image: string@cmpl-docker-images] {
    let ns = if ($n | is-empty) {[]} else {[-n $n]}
    ^$env.CONTCTL ...$ns save ...$image
}

# load images
export def image-load [-n: string@cmpl-docker-ns] {
    let ns = if ($n | is-empty) {[]} else {[-n $n]}
    ^$env.CONTCTL ...$ns load
}

# system prune
export def system-prune [-n: string@cmpl-docker-ns] {
    let ns = if ($n | is-empty) {[]} else {[-n $n]}
    ^$env.CONTCTL ...$ns system prune -f
}

# system prune all
export def system-prune-all [-n: string@cmpl-docker-ns] {
    let ns = if ($n | is-empty) {[]} else {[-n $n]}
    ^$env.CONTCTL ...$ns system prune --all --force --volumes
}

# remove image
export def image-remove [image: string@cmpl-docker-images -n: string@cmpl-docker-ns] {
    let ns = if ($n | is-empty) {[]} else {[-n $n]}
    ^$env.CONTCTL ...$ns rmi $image
}

# add new tag
export def image-tag [from: string@cmpl-docker-images  to: string -n: string@cmpl-docker-ns] {
    let ns = if ($n | is-empty) {[]} else {[-n $n]}
    ^$env.CONTCTL ...$ns tag $from $to
}

# push image
export def image-push [
    image: string@cmpl-docker-images
    --tag(-t): string
    -n: string@cmpl-docker-ns -i
] {
    let $insecure = if $i {[--insecure-registry]} else {[]}
    let ns = if ($n | is-empty) {[]} else {[-n $n]}
    if ($tag | is-empty) {
        ^$env.CONTCTL ...$ns ...$insecure push $image
    } else {
        ^$env.CONTCTL ...$ns tag $image $tag
        do -i {
            ^$env.CONTCTL ...$ns ...$insecure push $tag
        }
        ^$env.CONTCTL ...$ns rmi $tag
    }
}

# pull image
export def image-pull [image -n: string@cmpl-docker-ns -i] {
    let $insecure = if $i {[--insecure-registry]} else {[]}
    let ns = if ($n | is-empty) {[]} else {[-n $n]}
    ^$env.CONTCTL ...$ns ...$insecure pull $image
}

### list volume
export def volume-list [-n: string@cmpl-docker-ns] {
    let ns = if ($n | is-empty) {[]} else {[-n $n]}
    ^$env.CONTCTL ...$ns volume ls | from ssv -a
}

# create volume
export def volume-create [name: string -n: string@cmpl-docker-ns] {
    let ns = if ($n | is-empty) {[]} else {[-n $n]}
    ^$env.CONTCTL ...$ns volume create $name
}

# inspect volume
export def volume-inspect [name: string@cmpl-docker-volume -n: string@cmpl-docker-ns] {
    let ns = if ($n | is-empty) {[]} else {[-n $n]}
    ^$env.CONTCTL ...$ns volume inspect $name
}

# remove volume
export def volume-remove [...name: string@cmpl-docker-volume -n: string@cmpl-docker-ns] {
    let ns = if ($n | is-empty) {[]} else {[-n $n]}
    ^$env.CONTCTL ...$ns volume rm ...$name
}

# dump volume
export def volume-dump [
    name: string@cmpl-docker-volume
    --image(-i): string='debian'
    -n: string@cmpl-docker-ns
] {
    let id = random chars -l 6
    let ns = if ($n | is-empty) {[]} else {[-n $n]}
    ^$env.CONTCTL ...$ns ...[
        run --rm
        -v $"($name):/tmp/($id)"
        $image
        sh -c $'cd /tmp/($id); tar -zcf - *'
    ]
}

# restore volume
export def volume-restore [
    name: string@cmpl-docker-volume
    --from(-f): string
    --image(-i): string='debian'
    -n: string@cmpl-docker-ns
] {
    let id = random chars -l 6
    let src = random chars -l 6
    let ns = if ($n | is-empty) {[]} else {[-n $n]}
    ^$env.CONTCTL ...$ns ...[
        run --rm
        -v $"($name):/tmp/($id)"
        -v $"(host-path $from):/tmp/($src)"
        $image
        sh -c $'cd /tmp/($id); tar -zxf /tmp/($src)'
    ]
}


def host-path [path] {
    match ($path | str substring ..<1) {
        '/' => { $path }
        '=' => { $path | str substring 1.. }
        '~' => { [ $env.HOME ($path | str substring 2..) ] | path join }
        '$' => { $env | get ($path | str substring 1..) }
        _   => { [ $env.PWD $path ] | path join }
    }
}

# run
export def container-create [
    --name: string
    --debug(-x)
    --appimage
    --netadmin
    --proxy: string@cmpl-docker-run-proxy      # proxy
    --ssh(-s): string@cmpl-docker-run-sshkey   # specify ssh key
    --sshuser: string=root                              # default root
    --mnt(-m): string@cmpl-docker-run-vol      # mnt
    --vols(-v): any                                     # { host: container }
    --ports(-p): any                                    # { 8080: 80 }
    --envs(-e): any                                     # { FOO: BAR }
    --daemon(-d)
    --join(-j): string@cmpl-docker-containers  # join
    --network: string@cmpl-docker-network      # network
    --workdir(-w): string                               # workdir
    --entrypoint: string                                # entrypoint
    --dry-run
    --with-x
    --privileged(-P)
    --namespace(-n): string@cmpl-docker-ns
    image: string@cmpl-docker-images           # image
    ...cmd                                              # command args
] {
    mut args = []

    for b in [
        [$daemon
            [-d]
            [--rm -it]]
        [$debug
            [--cap-add=SYS_ADMIN --cap-add=SYS_PTRACE --security-opt seccomp=unconfined]]
        [$appimage
            [--device /dev/fuse --security-opt apparmor:unconfined]]
        [$privileged
            [--privileged]]
        [$netadmin
            [--cap-add=NET_ADMIN --device /dev/net/tun]]
        [$with_x
            [ -e $"DISPLAY=($env.DISPLAY)" -v /tmp/.X11-unix:/tmp/.X11-unix ]]
    ] {
        if ($b.0) {
            $args ++= $b.1
        } else {
            if ($b.2? | is-not-empty) {
                $args ++= $b.2
            }
        }
    }

    for i in [
        [$namespace
            [--namespace $namespace]]
        [$entrypoint
            [--entrypoint $entrypoint]]
        [$mnt
            [-v $mnt]]
        [$workdir
            [-w $workdir -v $"($env.PWD):($workdir)"]]
        [$vols
            ($vols | transpose k v | each {|x| [-v $"(host-path $x.k):($x.v)"]} | flatten)]
        [$envs
            ($envs | transpose k v | each {|x| [-e $"($x.k)=($x.v)"]} | flatten)]
        [$ports
            ($ports | transpose k v | each {|x| [-p $"($x.k):($x.v)"] } | flatten)]
        [$proxy
            [-e $"http_proxy=($proxy)" -e $"https_proxy=($proxy)"]]
    ] {
        if ($i.0 | is-not-empty) {
            $args ++= $i.1
        }
    }

    if ($ssh | is-not-empty) {
        let sshkey = cat ([$env.HOME .ssh $ssh] | path join) | split row ' ' | get 1
        $args ++= [-e $"ed25519_($sshuser)=($sshkey)"]
    }

    if ($join | is-not-empty) {
        let c = $"container:($join)"
        $args ++= [--pid $c --network $c]
        if $env.CONTCTL in ['podman'] { $args ++= [--uts $c --ipc $c] }
    }
    if ($network | is-not-empty) and ($join | is-empty) {
        $args ++= [--network $network]
    }

    let name = if ($name | is-empty) {
        let img = $image | split row '/' | last | str replace ':' '-'
        let now = date now | format date %m%d%H%M
        $"($img)_($now)"
    } else {
        $name
    }

    if $dry_run {
        echo ([docker run --name $name $args $image $cmd] | flatten | str join ' ')
    } else {
        ^$env.CONTCTL run --name $name ...$args $image ...($cmd | flatten)
    }
}
