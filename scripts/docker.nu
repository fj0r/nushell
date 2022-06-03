def dp [] {
    # podman ps --all --no-trunc --format='{{json .}}' | jq
    podman ps -a --format '{"id":"{{.ID}}", "image": "{{.Image}}", "name":"{{.Names}}", "cmd":"{{.Command}}", "port":"{{.Ports}}", "status":"{{.Status}}", "created":"{{.Created}}"}'
    | lines
    | each {|x|
            let r = ($x | from json)
            let t = ($r.created | str substring ',32' | into datetime)
            $r | update created ((date now) - $t)
           }
}

def di [] {
    podman images
    | from ssv -a
    | rename repo tag id created size
}
