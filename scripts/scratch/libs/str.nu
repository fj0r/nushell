export def skip-empty-lines [] {
    let o = $in
    mut s = 0
    for x in $o {
        if ($x | str replace -ra '\s' '' | is-not-empty) {
            break
        } else {
            $s += 1
        }
    }
    $o | range $s..
}

export def render [vars: record] {
    let tmpl = $in
    let v = $tmpl
    | parse -r '(?<!{){{(?<v>[^{}]*?)}}(?!})'
    | get v
    | uniq

    $v
    | reduce -f $tmpl {|i, a|
        let k = $i | str trim
        let k = if ($k | is-empty) { '_' } else { $k }
        $a | str replace --all $"{{($i)}}" ($vars | get $k | to text)
    }
}
