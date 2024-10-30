
def cmpl-xxh [] {
    let data = ssh-hosts
    $data.completion
    | each { |x|
        let uri = ($x.uri | fill -a l -w $data.max.uri -c ' ')
        let group = ($x.group | fill -a l -w $data.max.group -c ' ')
        let id = ($x.identfile | fill -a l -w $data.max.identfile -c ' ')
        {value: $x.value, description: $"\t($uri) ($group) ($id)" }
    }
}

export extern xxh [
    host: string@cmpl-xxh      # host
    ...cmd                              # cmd
    -v                                  # verbose
    -i: string                          # key
    -p: int                             # port
    -N                                  # n
    -T                                  # t
    -L                                  # l
    -R                                  # r
    -D                                  # d
    -J: string                          # j
    -W: string                          # w
]
