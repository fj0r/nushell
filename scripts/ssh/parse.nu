export def parse-ssh-file [group] {
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

export def ssh-list [] {
    rg -L -l 'Host' ~/.ssh
    | lines
    | each {|x| cat $x | parse-ssh-file $x}
    | flatten
}
