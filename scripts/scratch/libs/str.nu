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

export def render [scope: record] {
    let tmpl = $in
    $scope
    | transpose k v
    | reduce -f $tmpl {|i,a|
        let k = if $i.k == '_' { '' } else { $i.k }
        $a | str replace --all $"{($k)}" ($i.v | to text)
    }
}
