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
    [ $"($x):80" ]
}

def dr [
    img: string@"nu-complete docker images",
    -v: string@"nu-complete docker run vol",
    -p: string@"nu-complete docker run port",
] {
    let mnt = if not ($v|empty?) { [-v $v] } else { [] }
    docker run --rm -i -t $mnt $img
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
