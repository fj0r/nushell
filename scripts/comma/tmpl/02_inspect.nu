'. inspect'
| comma fun {|a,s,_| { index: $_, scope: $s, args: $a } | table -e }
