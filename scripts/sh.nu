export def "parse sh-export" [] {
    $in
    | lines
    | where {|x| not ($x | str trim  | str starts-with '#')}
    | parse -r 'export\s+(?P<k>[^=]+)=(?P<v>[^=]+)'
    | reduce -f {} {|x, a| $a| upsert $x.k $x.v}
}

