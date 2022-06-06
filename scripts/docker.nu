alias docker = podman

def dp [] {
    # docker ps --all --no-trunc --format='{{json .}}' | jq
    docker ps -a --format '{"id":"{{.ID}}", "image": "{{.Image}}", "name":"{{.Names}}", "cmd":"{{.Command}}", "port":"{{.Ports}}", "status":"{{.Status}}", "created":"{{.Created}}"}'
    | lines
    | each {|x|
            let r = ($x | from json)
            let t = ($r.created | str substring ',32' | into datetime)
            $r | update created ((date now) - $t)
           }
}

def di [] {
    docker images
    | from ssv -a
    | rename repo tag id created size
    | update size { |i| $i.size | into filesize }
}

def "nu-complete docker ps" [] {
    docker ps | from ssv -a
    | each {|x| {description: $x.NAMES value: $x.'CONTAINER ID'}}
}

def "nu-complete docker images" [] {
    docker images | from ssv | each {|x| $"($x.REPOSITORY):($x.TAG)"}
}

def da [ctn: string@"nu-complete docker ps", ...args] {
    if ($args|empty?) {
        docker exec -it $ctn /bin/sh -c "[ -e /bin/zsh ] && /bin/zsh || [ -e /bin/bash ] && /bin/bash || /bin/sh"
    } else {
        docker exec -it $ctn $args
    }
}

def dcp [lhs: string@"nu-complete docker ps", rhs: string@"nu-complete docker ps"] {
    docker cp $lhs $rhs
}

def dcr [ctn: string@"nu-complete docker ps"] {
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
    --debug: bool,
    --appimage: bool,
    --netadmin: bool,
    --proxy: bool,
    --ssh: string@"nu-complete docker run sshkey",  # specify ssh key
    --sshuser: string=root,                         # default root
    --cache: string,                                # cache
    --vol(-v): string@"nu-complete docker run vol",        # volume
    --port(-p): string@"nu-complete docker run port",       # port
    img: string@"nu-complete docker images",
] {
    let mnt = if not ($vol|empty?) { [-v $vol] } else { [] }
    let port = if not ($port|empty?) { [-p $port] } else { [] }
    let debug = if $debug { [--cap-add=SYS_ADMIN --cap-add=SYS_PTRACE --security-opt seccomp=unconfined] } else { [] }
    #let appimage = if $appimage { [--device /dev/fuse --security-opt apparmor:unconfined] } else { [] }
    let appimage = if $appimage { [--device /dev/fuse] } else { [] }
    let netadmin = if $netadmin { [--cap-add=NET_ADMIN --device /dev/net/tun] } else { [] }
    let clip = if true { [-e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix] } else { [] }
    let ssh = if not ($ssh|empty?) {
        let sshkey = (cat ([~/.ssh $ssh] | path join) | split row ' ' | get 1)
        [-e $"ed25519_($sshuser)=($sshkey)"]
    } else { [] }
    let proxy = if not ($proxy|empty?) { 
        let hostaddr = (hostname -I | split row ' ' | get 0)
        [-e $"http_proxy=http://($hostaddr):7890" -e $"https_proxy=http://($hostaddr):7890"]
    } else { [] }
    # todo:
    let cache = if not ($cache|empty?) {
        []
    } else { [] }
    let args = ([$ssh $proxy $debug $appimage $netadmin $clip $mnt $port $cache] | flatten)
    let name = $"($img | split row '/' | last | str replace ':' '-')_(date format %m%d%H%M)"  
    echo $"docker run --name ($name) --rm -it ($args|str collect ' ') ($img)"
    docker run --name $name --rm -it $args $img
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
def "registry list" [url: string, reg: string@"nu-complete registry list"] {
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
    | update size { |i| $i.size | into filesize }
}

def "bud ls" [] {
    buildah list | from ssv -a
}

def "bud ps" [] {
    buildah ps | from ssv -a
}

def "nu-complete bud ps" [] {
    bud ps | select 'CONTAINER ID' "CONTAINER NAME" | rename value description
}

def "bud rm" [
    id: string@"nu-complete bud ps"
] {
    buildah rm $id
}
