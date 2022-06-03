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
}

def "nu-complete docker ps" [] {
    docker ps | from ssv
    | reduce -f [] {|x, a|
        if ($x.NAMES|empty?) { $a } else { $a | append $x.NAMES} | append $x.'CONTAINER ID'
    }
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

