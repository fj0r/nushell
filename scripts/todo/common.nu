export def fmt-date [] {
    $in | format date '%FT%H:%M:%S'
}

export def block-edit [temp] {
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

export def split-cat [] {
    $in
    | each { split column ':' c tag  }
    | flatten
    | update tag { $in | split row '/' }
    | group-by c
    | items {|k,v| {cat: $k, tag: ($v | get tag | flatten | uniq)} }
    | reduce -f {} {|i,a| $a | insert $i.cat $i.tag }
}

export def cat-filter [] {
    let x = $in
    mut r = {
        not: []
        and: []
    }
    for i in ($x | transpose k v) {
        let p = $i.k | str substring ..<1
        if $p not-in ['&', '!'] { continue }
        let k = $i.k | str substring 1..
        let v = $i.v | each { $"($k):($in)" }
        match $p {
            '&' => {
                $r.and ++= $v
            }
            '!' => {
                $r.not ++= $v
            }
        }
    }
    $r
}

export def cat-to-cond [a b --empty-as-all] {
    $in
    | items {|k, v|
        if ($k | str substring ..<1) in ['&', '!'] { return '' }
        let t = if '' in $v and $empty_as_all {
            # Category without tag is equivalent to all tags
            ''
        } else {
            $v | each {Q $in} | str join ',' | $" and ($b) in \(($in)\)"
        } 
        $"\(($a) = (Q $k)($t)\)"
    }
    | filter {|x| $x | is-not-empty }
    | str join ' or '
}

export def cat-to-tag-id [
    ...c
    --empty-as-all
    --and
] {
    let cond = $in | cat-to-cond --empty-as-all=$empty_as_all 'c.name' 't.name'
    let s = [...$c, 't.id'] | str join ', '
    $"select ($s) from tag as t join category as c on t.category_id = c.id where ($cond)"
}

export def dbg [switch content -t:string] {
    if $switch {
        print $"(ansi grey)($t)│($content)(ansi reset)"
    }
}

export def db-upsert [db table pk --do-nothing] {
    let r = $in
    let d = if $do_nothing { 'NOTHING' } else {
        $"UPDATE SET ($r| items {|k,v | $"($k)=(Q $v)" } | str join ',')"
    }
    open $db | query db $"
        INSERT INTO ($table)\(($r | columns | str join ',')\)
        VALUES\(($r | values | each {Q $in} | str join ',')\)
        ON CONFLICT\(($pk)\) DO ($d);"
}

export def run [stmt] {
    open $env.TODO_DB | query db $stmt
}

export def 'str plain' [] {
    $in | str replace -ra '\e\[.*?m' ''
}

export def 'filter-empty' [] {
    $in
    | transpose k v
    | reduce -f {} {|i,a|
        if ($i.v | is-empty) {
            $a
        } else {
            $a | insert $i.k $i.v
        }
    }
}
