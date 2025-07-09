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

def cmpl-ssh-config [] {
    let p = [$env.HOME .ssh] | path join
    ls ([$p **/*] | path join | into glob)
    | get name
    | path relative-to $p
}

export def ssh-index-init [file:string@cmpl-ssh-config] {
    let group = rg -L -l 'Host' ([$env.HOME .ssh $file] | path join)
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

    let t = [$env.HOME .ssh index.toml] | path join
    if ($t | path exists) {
        open $t
    } else {
        {}
    }
    | merge deep $group
    | collect
    | save -f $t
}
