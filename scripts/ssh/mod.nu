export use scp.nu *
export use x.nu *
use parse.nu *


export def ensure-cache [cache paths action] {
    mut cfgs = []
    for i in $paths {
        let cs = (do -i {ls ($i | into glob)})
        if ($cs | is-not-empty) {
            $cfgs = ($cfgs | append $cs)
        }
    }
    let cfgs = $cfgs
    let ts = ($cfgs | sort-by modified | reverse | get 0.modified)
    if ($ts | is-empty) { return false }
    let tc = (do -i { ls $cache | get 0.modified })
    if not (($cache | path exists) and ($ts < $tc)) {
        mkdir ($cache | path dirname)
        do $action | save -f $cache
    }
    open $cache
}

export def 'str max-length' [] {
    $in | reduce -f 0 {|x, a|
        if ($x|is-empty) { return $a }
        let l = ($x | str length)
        if $l > $a { $l } else { $a }
    }
}

def cmpl-ssh-host [] {
    rg -LNI '^Host [a-z0-9_\-\.]+' ~/.ssh | lines | each {|x| $x | split row ' '| get 1}
}


def fmt-group [p] {
    $p | str replace $"($env.HOME)/.ssh/" ''
}

def ssh-hosts [] {
    let cache = $nu.cache-dir | path join 'ssh.json'
    ensure-cache $cache [~/.ssh/config ~/.ssh/config*/* ] { ||
        let data = (ssh-list | each {|x|
                let uri = $"($x.User)@($x.HostName):($x.Port)"
                {
                    value: $x.Host,
                    uri: $uri,
                    group: $"(fmt-group $x.Group)",
                    identfile: $"($x.IdentityFile)",
                }
        })

        let max = {
            value: ($data.value | str max-length),
            uri: ($data.uri | str max-length),
            group: ($data.group | str max-length),
            identfile: ($data.identfile | str max-length),
        }

        {max: $max, completion: $data}
    }
}

def cmpl-ssh [] {
    let data = ssh-hosts
    $data.completion
    | each { |x|
        let uri = ($x.uri | fill -a l -w $data.max.uri -c ' ')
        let group = ($x.group | fill -a l -w $data.max.group -c ' ')
        let id = ($x.identfile | fill -a l -w $data.max.identfile -c ' ')
        {value: $x.value, description: $"\t($uri) ($group) ($id)" }
    }
}

export extern main [
    host: string@cmpl-ssh      # host
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


