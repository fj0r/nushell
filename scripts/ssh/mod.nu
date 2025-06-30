export def 'str max-length' [] {
    $in | reduce -f 0 {|x, a|
        if ($x|is-empty) { return $a }
        let l = ($x | str length)
        if $l > $a { $l } else { $a }
    }
}

def cmpl-env [] {
    open ([$env.HOME .ssh index.toml] | path join)
    | get groups
    | transpose k v
    | get v
    | each {|x|
        $x | transpose k v | get v | transpose k v | get k
    }
    | flatten
    | uniq
}

def cmpl-group [] {
    open ([$env.HOME .ssh index.toml] | path join)
    | get groups
    | columns
}

export def ssh-switch  [
    environ?: string@cmpl-env
    --group(-g): string@cmpl-group
] {
    {
        environ: $environ
        group: $group
    }
    | to json
    | save -f ([$env.HOME .ssh index.json] | path join)

    mut o = []
    let c = open ([$env.HOME .ssh index.toml] | path join)
    for i in ($c.default? | transpose k v) {
        $o ++= [$"($i.k) ($i.v)"]
    }
    for i in ($c.host? | transpose k v) {
        $o ++= [$"Host ($i.k)"]
        for j in ($i.v | transpose k v) {
            $o ++= [$"    ($j.k) ($j.v)"]
        }
    }
    let gr = if ($group | is-empty) {
        $c.groups?
    } else {
        $c.groups? | select $group
    }
    for i in ($gr | transpose k v) {
        $o ++= [$"### ($i.k)"]
        for j in ($i.v | transpose k v) {
            $o ++= [$"Host ($j.k)"]
            let v = $j.v | get default
            let v = if ($environ | is-empty) {
                $v
            } else {
                $v | merge ($j.v | get -i $environ | default {})
            }
            for l in ($v | transpose k v) {
                if ($l.v | is-not-empty) {
                    $o ++= [$"    ($l.k) ($l.v)"]
                }
            }
        }
    }
    $o | save -f ([$env.HOME .ssh config] | path join)
}

export def cmpl-ssh [] {
    let t = [$env.HOME .ssh index.toml] | path join
    if not ($t | path exists) {
        ssh-index-init
        ssh-switch
    }
    let e = open ([$env.HOME .ssh index.json] | path join)
    open $t
    | get groups
    | do {
        let x = $in
        if ($e.group? | is-empty) {
            $x
        } else {
            $x | select $e.group
        }
    }
    | transpose k v
    | get v
    | each {|x|
        $x | transpose k v | each {|y|
            if ($e.environ? | is-empty) {
                $y.v.default
            } else {
                $y.v.default | merge ($y.v | get -i $e.environ | default {})
            }
            | insert name $y.k
        }
    }
    | flatten
    | each {|x|
        {
            value: $x.name
            description: $"($x.User? | default 'root')@($x.HostName? | default localhost):($x.Port? | default 22)"
        }
    }
}

export extern main [
    host: string@cmpl-ssh               # host
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

export use parse.nu *
export use utils.nu *
