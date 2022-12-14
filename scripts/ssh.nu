def "nu-complete ssh host" [] {
    rg -LNI '^Host [a-z0-9_\-\.]+' ~/.ssh | lines | each {|x| $x | split row ' '| get 1}
}

export def parse-ssh-file [group] {
    $in
    | parse -r '(?P<k>Host|HostName|User|Port|IdentityFile)\s+(?P<v>.+)'
    | append { k: Host, v: null}
    | reduce -f { rst: [], item: {Host: null} } {|it, acc|
          if $it.k == 'Host' {
              $acc | upsert rst ($acc.rst | append $acc.item)
                   | upsert item { Host : $it.v, HostName: null, Port: null, User: null, IdentityFile: null, Group: $group }
          } else {
              $acc | upsert item ($acc.item | upsert $it.k $it.v)
          }
      }
    | get rst
    | where {|x| not (($x.Host | is-empty) or $x.Host =~ '\*')}
}

export def ssh-list [] {
    rg -L -l 'Host' ~/.ssh
    | lines
    | each {|x| cat $x | parse-ssh-file $x}
    | flatten
}

def fmt-group [p] {
    $p | str replace $"($env.HOME)/.ssh/" ''
}

def "nu-complete ssh" [] {
    let cache = $'($env.HOME)/.cache/nu-complete/ssh.json'
    let ts = do -i { ls ~/.ssh/**/* | sort-by modified | reverse | get 0.modified }
    if ($ts | is-empty) { return [] }
    let tc = do -i { ls $cache | get 0.modified }
    if not (($cache | path exists) and ($ts < $tc)) {
        mkdir (dirname $cache)
        ssh-list
        | each {|x| {value: $x.Host, description: $"($x.User)@($x.HostName):($x.Port)\t(fmt-group $x.Group)<($x.IdentityFile)>" } }
        | save $cache
    }
    cat $cache | from json
}

export extern ssh [
    host: string@"nu-complete ssh"      # host
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
