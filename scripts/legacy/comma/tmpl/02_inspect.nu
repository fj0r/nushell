'computed'
| comma val computed {|a,s,m| $'($s.created)($a)' }

'loga'
| comma val filter {|a,s,m,_|
    if $m == 'completion' { return }
    do $env.comma_index.tips 'received arguments' $a
}

'. created'
| comma fun {|a, s| $s.computed } {
    filter: [loga]
    desc: "created"
}

'. inspect'
| comma fun {|a,s,_| { index: $_, scope: $s, args: $a } | table -e }
