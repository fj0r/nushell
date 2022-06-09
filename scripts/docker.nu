alias docker = podman

def dp [] {
    # docker ps --all --no-trunc --format='{{json .}}' | jq
    docker ps -a --format '{"id":"{{.ID}}", "image": "{{.Image}}", "name":"{{.Names}}", "cmd":"{{.Command}}", "port":"{{.Ports}}", "status":"{{.Status}}", "created":"{{.Created}}"}'
    | lines
    | each {|x|
            let r = ($x | from json)
            let t = ($r.created | str substring ',32' | into datetime ) - 8hr
            $r | upsert created ((date now) - $t)
           }
}

def di [] {
    docker images
    | from ssv -a
    | rename repo tag id created size
    | upsert size { |i| $i.size | into filesize }
}

def "nu-complete docker ps" [] {
    docker ps | from ssv -a
    | each {|x| {description: $x.NAMES value: $x.'CONTAINER ID'}}
}

def "nu-complete docker container" [] {
    docker ps | from ssv -a
    | each {|x| {description: $x.'CONTAINER ID' value: $x.NAMES}}
}

def "nu-complete docker images" [] {
    docker images | from ssv | each {|x| $"($x.REPOSITORY):($x.TAG)"}
}

def da [
    ctn: string@"nu-complete docker container"
    ...args
] {
    if ($args|empty?) {
        docker exec -it $ctn /bin/sh -c "[ -e /bin/zsh ] && /bin/zsh || [ -e /bin/bash ] && /bin/bash || /bin/sh"
    } else {
        docker exec -it $ctn $args
    }
}

def dcp [lhs: string@"nu-complete docker container", rhs: string@"nu-complete docker container"] {
    docker cp $lhs $rhs
}

def dcr [ctn: string@"nu-complete docker container"] {
    docker container rm -f $ctn
}

def dis [img: string@"nu-complete docker images"] {
    docker inspect $img
}

def dh [img: string@"nu-complete docker images"] {
    docker history --no-trunc $img | from ssv -a
}

def dsv [img: string@"nu-complete docker images"] {
    docker save $img
}

alias dld = docker load

def dsp [] {
    docker system prune -f
}

alias dspall = system prune --all --force --volumes

def drmi [img: string@"nu-complete docker images"] {
    docker rmi $img
}

def dtg [from: string@"nu-complete docker images"  to: string] {
    docker tag $from $to
}

def dps [img: string@"nu-complete docker images"] {
    docker push $img
}

alias dpl = docker pull

### volume
def dvl [] {
    docker volume ls | from ssv -a
}

def "nu-complete docker volume" [] {
    dvl | get name
}

def dvc [name: string] {
    docker volume create
}

def dvi [name: string@"nu-complete docker volume"] {
    docker volume inspect $name
}

def dvr [...name: string@"nu-complete docker volume"] {
    docker volume rm $name
}

### run
def "nu-complete docker run vol" [] {
    [
        $"($env.PWD):/world"
        $"($env.PWD):/app"
        $"($env.PWD):/srv"
    ]
}

def "nu-complete docker run port" [ctx: string, pos: int] {
    let x = (ns | get 1.port | into int ) + 1
    # todo:
    [ $"($x):80" ]
}

def "nu-complete docker run sshkey" [ctx: string, pos: int] {
    (do { cd ~/.ssh; ls **/*.pub } | get name)
}

def dr [
    --debug(-x): bool
    --appimage: bool
    --netadmin(-n): bool
    --proxy: bool
    --ssh(-s): string@"nu-complete docker run sshkey"   # specify ssh key
    --sshuser: string=root                              # default root
    --cache(-c): string                                 # cache
    --vol(-v): string@"nu-complete docker run vol"      # volume
    --port(-p): string@"nu-complete docker run port"    # port
    --envs(-e): any                                     # { FOO: BAR }
    --daemon(-d): bool
    --attach(-a): string@"nu-complete docker container" # attach
    --entrypoint: string                                # entrypoint
    --dry-run: bool
    img: string@"nu-complete docker images"             # image
    ...cmd                                              # command args
] {
    let entrypoint = if ($entrypoint|empty?) { [] } else { [--entrypoint $entrypoint] }
    let daemon = if $daemon { [-d] } else { [--rm -it] }
    let mnt = if ($vol|empty?) { [] } else { [-v $vol] }
    let port = if ($port|empty?) { [] } else { [-p $port] }
    let envs = if ($envs|empty?) { [] } else { $envs | transpose k v | each {|x| $"-e ($x.k)=($x.v)"} }
    let debug = if $debug { [--cap-add=SYS_ADMIN --cap-add=SYS_PTRACE --security-opt seccomp=unconfined] } else { [] }
    #let appimage = if $appimage { [--device /dev/fuse --security-opt apparmor:unconfined] } else { [] }
    let appimage = if $appimage { [--device /dev/fuse] } else { [] }
    let netadmin = if $netadmin { [--cap-add=NET_ADMIN --device /dev/net/tun] } else { [] }
    let clip = if true { [-e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix] } else { [] }
    let ssh = if ($ssh|empty?) { [] } else {
        let sshkey = (cat ([~/.ssh $ssh] | path join) | split row ' ' | get 1)
        [-e $"ed25519_($sshuser)=($sshkey)"]
    }
    let proxy = if ($proxy|empty?) { [] } else {
        let hostaddr = (hostname -I | split row ' ' | get 0)
        [-e $"http_proxy=http://($hostaddr):7890" -e $"https_proxy=http://($hostaddr):7890"]
    }
    let attach = if ($attach|empty?) { [] } else {
        let c = $"container:($attach)"
        [--uts $c --ipc $c --pid $c --network $c]
    }
    let cache = if ($cache|empty?) { [] } else { [-v $cache] }
    let args = ([$entrypoint $attach $daemon $envs $ssh $proxy $debug $appimage $netadmin $clip $mnt $port $cache] | flatten)
    let name = $"($img | split row '/' | last | str replace ':' '-')_(date format %m%d%H%M)"
    if $dry-run {
        echo $"docker run --name ($name) ($args|str collect ' ') ($img) ($cmd | flatten)"
    } else {
        docker run --name $name $args $img ($cmd | flatten)
    }
}

def "nu-complete docker dev env" [] {
    [ io io:rs io:hs io:jpl io:go ng ng:pg ]
}

let __dx_cache = {
    hs: 'stack:/opt/stack'
    rs: 'cargo:/opt/cargo'
    go: 'gopkg:/opt/gopkg'
    ng: 'ng:/srv'
    pg: 'pg:/var/lib/postgresql/data'
}

def dx [
    --dry-run(-v): bool
    --mount-cache: bool
    --attach(-a): string@"nu-complete docker container" # attach
    dx:string@"nu-complete docker dev env"
    --envs(-e): any                                     # { FOO: BAR }
    ...cmd                                              # command args
] {
    # -p 8080:80
    # --cache
    let c = do -i {$__dx_cache | transpose k v | where {|x| $dx | str contains $x.k} | get v.0}
    let c = if ($c|empty?) { '' } else if $mount-cache {
        let c = ( $c
                | split row ':'
                | each -n {|x| if $x.index == 1 { $"/cache($x.item)" } else { $x.item } }
                | str collect ':'
                )
        $"($env.HOME)/.cache/($c)"
    } else {
        $"($env.HOME)/.cache/($c)"
    }
    if $dry-run {
        print $"cache: ($c)"
        dr --dry-run --attach $attach --envs $envs --cache $c -v $"($env.PWD):/world" --debug --proxy --ssh id_ed25519.pub $dx $cmd
    } else {
        dr --attach $attach --envs $envs --cache $c -v $"($env.PWD):/world" --debug --proxy --ssh id_ed25519.pub $dx $cmd
    }
}


def "nu-complete registry list" [cmd: string, offset: int] {
    let cmd = ($cmd | split row ' ')
    let url = do -i { $cmd | get 2 }
    let reg = do -i { $cmd | get 3 }
    let tag = do -i { $cmd | get 4 }
    if ($reg|empty?) {
        if (do -i { $env.REGISTRY_TOKEN } | empty?) {
            fetch $"($url)/v2/_catalog"
        } else {
            fetch -H [authorization $"Basic ($env.REGISTRY_TOKEN)"] $"($url)/v2/_catalog"
        } | get repositories
    } else if ($tag|empty?) {
        if (do -i { $env.REGISTRY_TOKEN } | empty?) {
            fetch $"($url)/v2/($reg)/tags/list"
        } else {
            fetch -H [authorization $"Basic ($env.REGISTRY_TOKEN)"] $"($url)/v2/($reg)/tags/list"
        } | get tags
    }
}

### docker registry list
def "registry list" [
    url: string
    reg: string@"nu-complete registry list"
] {
    if (do -i { $env.REGISTRY_TOKEN } | empty?) {
        fetch $"($url)/v2/($reg)/tags/list"
    } else {
        fetch -H [authorization $"Basic ($env.REGISTRY_TOKEN)"] $"($url)/v2/($reg)/tags/list"
    } | get tags
}

### buildah

def "bud img" [] {
    buildah images | from ssv -a
    | rename repo tag id created size
    | upsert size { |i| $i.size | into filesize }
}

def "bud ls" [] {
    buildah list | from ssv -a | rename  id builder image-id image container
}

def "bud ps" [] {
    buildah ps | from ssv -a | rename  id builder image-id image container
}

def "nu-complete bud ps" [] {
    bud ps | select 'CONTAINER ID' "CONTAINER NAME" | rename value description
}

def "bud rm" [
    id: string@"nu-complete bud ps"
] {
    buildah rm $id
}
