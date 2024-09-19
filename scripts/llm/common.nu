export def 'similarity cosine' [a b] {
    if ($a | length) != ($b | length) {
        print "The lengths of the vectors must be equal."
    }
    $a | zip $b | reduce -f {p: 0, a: 0, b: 0} {|i,a|
        {
            p: ($a.p + ($i.0 * $i.1))
            a: ($a.a + ($i.0 * $i.0))
            b: ($a.b + ($i.1 * $i.1))
        }
    }
    | $in.p / (($in.a | math sqrt) * ($in.b | math sqrt))
}

export def 'json-to-string' [json] {
    $json | to json -r | str replace '"' '\"' -a
}

export def block-editor [temp] {
    let content = $in
    let tf = mktemp -t $temp
    $content | save -f $tf
    ^$env.EDITOR $tf
    let c = open $tf --raw
    rm -f $tf
    $c
}

export def Q [...t] {
    let s = $t | str join '' | str replace -a "'" "''"
    $"'($s)'"
}

export def db-upsert [db table pkn pk] {
    let r = $in
    open $db | query db $"
        INSERT INTO ($table)\(($r | columns | str join ',')\)
        VALUES\(($r | values | each {Q $in} | str join ',')\)
        ON CONFLICT\(($pkn)\) DO UPDATE SET ($r| items {|k,v | $"($k)=(Q $v)" } | str join ',');"
}
