export-env {
    for c in [nerdctl podman docker] {
        if not (which $c | is-empty) {
            $env.docker-cli = $c
            break
        }
    }
}

def --wrapped with-flag [...flag] {
    if ($in | is-empty) { [] } else { [...$flag $in] }
}

def "nu-complete docker ns" [] {
    if $env.docker-cli == 'nerdctl' {
        ^$env.docker-cli namespace list
        | from ssv -a
        | each {|x| { value: $x.NAMES }}
    } else {
        []
    }
}

# list containers
export def container-list [
    -n: string@"nu-complete docker ns"
    container?: string@"nu-complete docker containers"
    --all(-a)
] {
    let cli = $env.docker-cli
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
        let r = ^$cli ...($n | with-flag -n) inspect $container
            | from json
            | get 0
        let image = $r.Image
        let img = ^$cli ...($n | with-flag -n) inspect $image
            | from json
            | get 0
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
            image: $image
            created: $r.Created
            id: $r.Id
            ports: $p
            env: $imgEnv
            mounts: $m
            entrypoint: $r.Path?
            args: $r.Args
        }
    }
}

# list images
export def image-list [
    -n: string@"nu-complete docker ns"
    img?: string@"nu-complete docker images"
] {
    if ($img | is-empty) {
        ^$env.docker-cli ...($n | with-flag -n) images
            | from ssv -a
            | each {|x|
                let size = $x.SIZE | into filesize
                let path = $x.REPOSITORY | split row '/'
                let image = $path | last
                let repo = $path | range ..(($path|length) - 2) | str join '/'
                {
                    repo: $repo
                    image: $image
                    tag: $x.TAG
                    id: $x.'IMAGE ID'
                    created: $x.CREATED
                    size: $size
                }
            }
    } else {
        let r = ^$env.docker-cli ...($n | with-flag -n) inspect $img
            | from json
            | get 0
        let e = $r.Config.Env?
            | reduce -f {} {|i, a|
                let x = $i | split row '='
                $a | upsert $x.0 $x.1?
            }
        {
            id: $r.Id
            created: $r.Created
            author: $r.Author
            arch: $r.Architecture
            os: $r.Os
            size: $r.Size
            labels: $r.Labels?
            env: $e
            entrypoint: $r.Config.Entrypoint?
            cmd: $r.Config.Cmd?
        }
    }
}

def "nu-complete docker ps" [] {
    ^$env.docker-cli ps
    | from ssv -a
    | each {|x| {description: $x.NAMES value: $x.'CONTAINER ID'}}
}

def "nu-complete docker containers" [] {
    ^$env.docker-cli ps
    | from ssv -a
    | each {|x| {description: $x.'CONTAINER ID' value: $x.NAMES}}
}

def "nu-complete docker all containers" [] {
    ^$env.docker-cli ps -a
    | from ssv -a
    | each {|x| {description: $x.'CONTAINER ID' value: $x.NAMES}}
}

def "nu-complete docker images" [] {
    ^$env.docker-cli images
    | from ssv
    | each {|x| $"($x.REPOSITORY):($x.TAG)"}
}


# container log
export def container-log [ctn: string@"nu-complete docker containers"
    -l: int = 100 # line
    -n: string@"nu-complete docker ns" # namespace
] {
    let l = if $l == 0 { [] } else { [--tail $l] }
    ^$env.docker-cli ...($n | with-flag -n) logs -f ...$l $ctn
}

# attach container
export def --wrapped container-attach [
    ctn: string@"nu-complete docker containers"
    -n: string@"nu-complete docker ns"
    ...args
] {
    let ns = $n | with-flag -n
    if ($args|is-empty) {
        ^$env.docker-cli ...$ns exec -it $ctn /bin/sh -c "[ -e /bin/zsh ] && /bin/zsh || [ -e /bin/bash ] && /bin/bash || /bin/sh"
    } else {
        ^$env.docker-cli ...$ns exec -it $ctn ...$args
    }
}

def "nu-complete docker cp" [cmd: string, offset: int] {
    let argv = $cmd | str substring ..$offset | split row ' '
    let p = if ($argv | length) > 2 { $argv | get 2 } else { $argv | get 1 }
    let ctn = ^$env.docker-cli ps
        | from ssv -a
        | each {|x| {description: $x.'CONTAINER ID' value: $"($x.NAMES):" }}
    let n = $p | split row ':'
    if $"($n | get 0):" in ($ctn | get value) {
        ^$env.docker-cli exec ($n | get 0) sh -c $"ls -dp ($n | get 1)*"
        | lines
        | each {|x| $"($n | get 0):($x)"}
    } else {
        let files = do -i {
            ls -a $"($p)*"
            | each {|x| if $x.type == dir { $"($x.name)/"} else { $x.name }}
        }
        $files | append $ctn
    }
}

# copy file
export def container-copy-file [
    lhs: string@"nu-complete docker cp",
    rhs: string@"nu-complete docker cp"
] {
    ^$env.docker-cli cp $lhs $rhs
}

# remove container
export def container-remove [ctn: string@"nu-complete docker all containers" -n: string@"nu-complete docker ns"] {
    ^$env.docker-cli ...($n | with-flag -n) container rm -f $ctn
}


# history
export def container-history [img: string@"nu-complete docker images" -n: string@"nu-complete docker ns"] {
    ^$env.docker-cli ...($n | with-flag -n) history --no-trunc $img | from ssv -a
}


# save images
export def image-save [-n: string@"nu-complete docker ns" ...img: string@"nu-complete docker images"] {
    ^$env.docker-cli ...($n | with-flag -n) save ...$img
}

# load images
export def image-load [-n: string@"nu-complete docker ns"] {
    ^$env.docker-cli ...($n | with-flag -n) load
}

# system prune
export def system-prune [-n: string@"nu-complete docker ns"] {
    ^$env.docker-cli ...($n | with-flag -n) system prune -f
}

# system prune all
export def system-prune-all [-n: string@"nu-complete docker ns"] {
    ^$env.docker-cli ...($n | with-flag -n) system prune --all --force --volumes
}

# remove image
export def image-remove [img: string@"nu-complete docker images" -n: string@"nu-complete docker ns"] {
    ^$env.docker-cli ...($n | with-flag -n) rmi $img
}

# add new tag
export def image-tag [from: string@"nu-complete docker images"  to: string -n: string@"nu-complete docker ns"] {
    ^$env.docker-cli ...($n | with-flag -n) tag $from $to
}

# push image
export def image-push [
    img: string@"nu-complete docker images"
    --tag(-t): string
    -n: string@"nu-complete docker ns" -i
] {
    let $insecure = if $i {[--insecure-registry]} else {[]}
    if ($tag | is-empty) {
        ^$env.docker-cli ...($n | with-flag -n) ...$insecure push $img
    } else {
        ^$env.docker-cli ...($n | with-flag -n) tag $img $tag
        do -i {
            ^$env.docker-cli ...($n | with-flag -n) ...$insecure push $tag
        }
        ^$env.docker-cli ...($n | with-flag -n) rmi $tag
    }
}

# pull image
export def image-pull [img -n: string@"nu-complete docker ns" -i] {
    let $insecure = if $i {[--insecure-registry]} else {[]}
    ^$env.docker-cli ...($n | with-flag -n) ...$insecure pull $img
}

### list volume
export def volume-list [-n: string@"nu-complete docker ns"] {
    ^$env.docker-cli ...($n | with-flag -n) volume ls | from ssv -a
}

def "nu-complete docker volume" [] {
    dvl | get name
}

# create volume
export def volume-create [name: string -n: string@"nu-complete docker ns"] {
    ^$env.docker-cli ...($n | with-flag -n) volume create
}

# inspect volume
export def volume-inspect [name: string@"nu-complete docker volume" -n: string@"nu-complete docker ns"] {
    ^$env.docker-cli ...($n | with-flag -n) volume inspect $name
}

# remove volume
export def volume-remove [...name: string@"nu-complete docker volume" -n: string@"nu-complete docker ns"] {
    ^$env.docker-cli ...($n | with-flag -n) volume rm ...$name
}

### run
def "nu-complete docker run vol" [] {
    [
        $"($env.PWD):/world"
        $"($env.PWD):/app"
        $"($env.PWD):/srv"
        $"($env.HOME)/.config/nvim:/etc/nvim"
    ]
}

def "nu-complete docker run sshkey" [ctx: string, pos: int] {
    (do { cd ~/.ssh; ls **/*.pub } | get name)
}

def "nu-complete docker run proxy" [] {
    let hostaddr = do -i { hostname -I | split row ' ' | get 0 }
    [ $"http://($hostaddr):7890" $"http://($hostaddr):" ]
}

def host-path [path] {
    match ($path | str substring ..1) {
        '/' => { $path }
        '~' => { [ $nu.home-path ($path | str substring 2..) ] | path join }
        '$' => { ($env | get ($path | str substring 1..)) }
        _   => { [ $env.PWD $path ] | path join }
    }
}

# run
export def container-create [
    --debug(-x)
    --appimage
    --netadmin
    --proxy: string@"nu-complete docker run proxy"      # proxy
    --ssh(-s): string@"nu-complete docker run sshkey"   # specify ssh key
    --sshuser: string=root                              # default root
    --cache(-c): string                                 # cache
    --mnt(-m): string@"nu-complete docker run vol"      # mnt
    --vols(-v): any                                     # { host: container }
    --ports(-p): any                                    # { 8080: 80 }
    --envs(-e): any                                     # { FOO: BAR }
    --daemon(-d)
    --attach(-a): string@"nu-complete docker containers" # attach
    --workdir(-w): string                               # workdir
    --entrypoint: string                                # entrypoint
    --dry-run
    --with-x
    --privileged(-P)
    --namespace(-n): string@"nu-complete docker ns"
    img: string@"nu-complete docker images"             # image
    ...cmd                                              # command args
] {
    let ns = $namespace | with-flag -n
    let entrypoint = $entrypoint | with-flag --entrypoint
    let daemon = if $daemon { [-d] } else { [--rm -it] }
    let mnt = $mnt | with-flag -v
    let workdir = if ($workdir | is-empty) {[]} else {[-w $workdir -v $"($env.PWD):($workdir)"]}
    let vols = if ($vols|is-empty) { [] } else { $vols | transpose k v | each {|x| [-v $"(host-path $x.k):($x.v)"]} | flatten }
    let envs = if ($envs|is-empty) { [] } else { $envs | transpose k v | each {|x| [-e $"($x.k)=($x.v)"]} | flatten }
    let ports = if ($ports|is-empty) { [] } else { $ports | transpose k v | each {|x| [-p $"($x.k):($x.v)"] } | flatten }
    let debug = if $debug {[--cap-add=SYS_ADMIN --cap-add=SYS_PTRACE --security-opt seccomp=unconfined]} else {[]}
    #let appimage = if $appimage {[--device /dev/fuse --security-opt apparmor:unconfined]} else {[]}
    let privileged = if $privileged {[--privileged]} else {[]}
    let appimage = if $appimage {[--device /dev/fuse]} else {[]}
    let netadmin = if $netadmin {[--cap-add=NET_ADMIN --device /dev/net/tun]} else {[]}
    let with_x = if $with_x {[
        -e $"DISPLAY=($env.DISPLAY)"
        -v /tmp/.X11-unix:/tmp/.X11-unix
        ]} else {[]}
    let ssh = if ($ssh|is-empty) { [] } else {
        let sshkey = cat ([$env.HOME .ssh $ssh] | path join) | split row ' ' | get 1
        [-e $"ed25519_($sshuser)=($sshkey)"]
    }
    let proxy = if ($proxy|is-empty) { [] } else {
        [-e $"http_proxy=($proxy)" -e $"https_proxy=($proxy)"]
    }
    let attach = if ($attach|is-empty) { [] } else {
        let c = $"container:($attach)"
        [--uts $c --ipc $c --pid $c --network $c]
    }
    let cache = $cache | with-flag -v
    let args = [
        $privileged $entrypoint $attach $daemon
        $ports $envs $ssh $proxy
        $debug $appimage $netadmin $with_x
        $mnt $vols $workdir $cache
    ] | flatten
    let name = $"($img | split row '/' | last | str replace ':' '-')_(date now | format date %m%d%H%M)"
    if $dry_run {
        echo ([docker $ns run --name $name $args $img $cmd] | flatten | str join ' ')
    } else {
        ^$env.docker-cli ...$ns run --name $name ...$args $img ...($cmd | flatten)
    }
}

def has [name] {
    $name in ($in | columns) and (not ($in | get $name | is-empty))
}

def "nu-complete registry show" [cmd: string, offset: int] {
    let new = $cmd | str ends-with ' '
    let cmd = $cmd | split row ' '
    let url = $cmd.3?
    let reg = $cmd.4?
    let tag = $cmd.5?
    let auth = if ($env | has 'REGISTRY_TOKEN') {
        [-H $"Authorization: Basic ($env.REGISTRY_TOKEN)"]
    } else {
        []
    }
    if ($tag | is-empty) and (not $new) or ($reg | is-empty) {
        curl -sSL ...$auth $"($url)/v2/_catalog"
        | from json | get repositories
    } else {
        curl -sSL ...$auth $"($url)/v2/($reg)/tags/list"
        | from json | get tags
    }
}

### docker registry show
export def "docker registry show" [
    url: string
    reg?: string@"nu-complete registry show"
    tag?: string@"nu-complete registry show"
] {
    let header = if ($env | has 'REGISTRY_TOKEN') {
        [-H $"Authorization: Basic ($env.REGISTRY_TOKEN)"]
    } else {
        []
    }
    | append [-H 'Accept: application/vnd.oci.image.manifest.v1+json']
    if ($reg | is-empty) {
        curl -sSL ...$header $"($url)/v2/_catalog" | from json | get repositories
    } else if ($tag | is-empty) {
        curl -sSL ...$header $"($url)/v2/($reg)/tags/list" | from json | get tags
    } else {
        curl -sSL ...$header $"($url)/v2/($reg)/manifests/($tag)" | from json
    }
}

### docker registry delete
export def "docker registry delete" [
    url: string
    reg: string@"nu-complete registry show"
    tag: string@"nu-complete registry show"
] {
    let header = if ($env | has 'REGISTRY_TOKEN') {
        [-H $"Authorization: Basic ($env.REGISTRY_TOKEN)"]
    } else {
        []
    }
    | append [-H 'Accept: application/vnd.oci.image.manifest.v1+json']
    #| append [-H 'Accept: application/vnd.docker.distribution.manifest.v2+json']
    let digest = do -i {
        curl -sSI ...$header $"($url)/v2/($reg)/manifests/($tag)"
        | rg docker-content-digest
        | split row ' '
        | get 1
        | str trim
    }
    print -e $digest
    if not ($digest | is-empty) {
        curl -sSL -X DELETE ...$header $"($url)/v2/($reg)/manifests/($digest)"
    } else {
        'not found'
    }
}

### buildah

export def "bud img" [] {
    buildah images
    | from ssv -a
    | rename repo tag id created size
    | upsert size { |i| $i.size | into filesize }
}

export def "bud ls" [] {
    buildah list
    | from ssv -a
    | rename id builder image-id image container
}

export def "bud ps" [] {
    buildah ps
    | from ssv -a
    | rename id builder image-id image container
}

def "nu-complete bud ps" [] {
    bud ps
    | select 'CONTAINER ID' "CONTAINER NAME"
    | rename value description
}

export def "bud rm" [
    id: string@"nu-complete bud ps"
] {
    buildah rm $id
}

export alias dp = container-list
export alias di = image-list
export alias dl = container-log
export alias da = container-attach
export alias dcp = container-copy-file
export alias dcr = container-remove
export alias dh = container-history
export alias dsv = image-save
export alias dld = image-load
export alias dsp = system-prune
export alias dspall = system-prune-all
export alias drmi = image-remove
export alias dt = image-tag
export alias dps = image-push
export alias dpl = image-pull
export alias dvl = volume-list
export alias dvc = volume-create
export alias dvi = volume-inspect
export alias dvr = volume-remove
export alias dr = container-create
