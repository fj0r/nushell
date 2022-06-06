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

def dcr [ctn: string@"nu-complete docker ps"] {
    docker container rm -f $ctn
}

def dis [ img: string@"nu-complete docker images" ] {
    docker inspect $img
}

def dsv [ img: string@"nu-complete docker images" ] {
    docker save $img
}

alias dld = docker load

def dsp [] {
    podman system prune -f
}

def drmi [ img: string@"nu-complete docker images" ] {
    docker rmi $img
}
###
def "nu-complete docker run vol" [] {
    [ $"($env.PWD):/world" ]
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
    let mnt = if not ($v|empty?) { $"-v=($v)" }
    docker run --rm -i -t $mnt $img
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
