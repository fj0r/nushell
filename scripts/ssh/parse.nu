def parse-ssh-file [group] {
    $in
    | parse -r '(?<k>Host|HostName|User|Port|IdentityFile)\s+(?<v>.+)'
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

export def ssh-index-init [] {
    let groups = rg -L -l 'Host' ~/.ssh
    | lines
    | reduce -f {} {|x,a|
        let n = $x | path parse | get stem
        let v = cat $x | parse-ssh-file $x
        let v = $v | reduce -f {} {|y,b|
            let o = $y | reject Host Group
            | transpose k v
            | reduce -f {} {|z, c|
                if ($z.v | is-empty) {
                    $c
                } else {
                    $c | upsert $z.k $z.v
                }
            }
            $b | insert $y.Host {default: $o}
        }
        $a | upsert $n $v
    }
    | wrap groups

    if ('~/.ssh/index.toml' | path exists) {
        open ~/.ssh/index.toml
    } else {
        {
            default: {
                Compression: yes
            }
            host: {
                *: {
                    ForwardAgent: yes
                }
                localhost*: {
                    StrictHostKeyChecking: no
                    UserKnownHostsFile: /dev/null
                }
            }
        }
    }
    | merge deep $groups
    | collect
    | save -f ~/.ssh/index.toml
}
