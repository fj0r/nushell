export def 'str max-length' [] {
    $in | reduce -f 0 {|x, a|
        if ($x|is-empty) { return $a }
        let l = ($x | str length)
        if $l > $a { $l } else { $a }
    }
}

def cmpl-env [] {
    open ~/.ssh/index.toml
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
    open ~/.ssh/index.toml
    | get groups
    | columns
}

export def ssh-switch [
    --environ(-e): string@cmpl-env
    --group(-g): string@cmpl-group
] {
    mut o = []
    let c = open ~/.ssh/index.toml
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
                $v | merge ($j.v | get $environ)
            }
            for l in ($v | transpose k v) {
                $o ++= [$"    ($l.k) ($l.v)"]
            }
        }
    }
    for i in $o {
        print $i
    }
}

def cmpl-ssh [] {
    open ~/.ssh/index.toml
    | get groups
    | transpose k v
    | get v
    | each {|x|
        $x | transpose k v | each {|y|
            $y.v.default | insert name $y.k
        }
    }
    | flatten
    | each {|x|
        {
            value: $x.name
            description: $"($x.name)@($x.host):($x.port)"
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


