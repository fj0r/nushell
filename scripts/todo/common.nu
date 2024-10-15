export def Q [...t] {
    let s = $t | str join '' | str replace -a "'" "''"
    $"'($s)'"
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

export def split-cat [] {
    $in
    | each { split column ':' c tag  }
    | flatten
    | update tag { $in | split row '/' }
    | group-by c
    | items {|k,v| {cat: $k, tag: ($v | get tag | flatten | uniq)} }
    | reduce -f {} {|i,a| $a | insert $i.cat $i.tag }
}

export def fmt-date [] {
    $in | format date '%FT%H:%M:%S'
}

export def cat-to-cond [a b] {
    $in
    | split-cat
    | items {|k, v|
        let t = if '' in $v {
            # Category without tag is equivalent to all tags
            ''
        } else {
            $v | each {Q $in} | str join ',' | $" and ($b) in \(($in)\)"
        } 
        $"\(($a) = (Q $k)($t)\)"
    }
    | str join ' or '
}

export def cat-to-tag-id [
    ...c
    --and
] {
    let cond = $in | cat-to-cond 'c.name' 't.name'
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
