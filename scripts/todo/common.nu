export def fmt-date [] {
    $in | format date '%FT%H:%M:%S'
}

def variants-edit [file? --line:int] {
    if ($line | is-empty) {
        ^$env.EDITOR $file
    } else {
        if ($env.EDITOR | find vim | is-not-empty) {
            ^$env.EDITOR $"+($line)" $file
        } else {
            ^$env.EDITOR $file
        }
    }
}

export def block-edit [temp --line:int] {
    let content = $in
    let tf = mktemp -t $temp
    $content | save -f $tf
    variants-edit $tf --line $line
    let c = open $tf --raw
    rm -f $tf
    $c
}

export def Q [...t] {
    let s = $t | str join '' | str replace -a "'" "''"
    $"'($s)'"
}

export def tag-tree [] {
    $"with recursive t as \(
        select parent_id, id, name from tag where parent_id = -1
        union all
        select t1.parent_id, t1.id, t.name || ':' || t1.name as name from tag as t1
        join t on t1.parent_id= t.id
    \), ts as \(
        select id, parent_id, name from t order by length\(name\) desc
    \), tags as \(
        select id, name from ts where parent_id != -1 group by id
    \)
    "
}


# TODO: rm
export def split-cat [] {
    $in
    | each { split column ':' c tag  }
    | flatten
    | update tag { $in | split row '/' }
    | group-by c
    | items {|k,v| {cat: $k, tag: ($v | get tag | flatten | uniq)} }
    | reduce -f {} {|i,a| $a | insert $i.cat $i.tag }
}

# TODO: rm
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

# TODO: rm
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

# TODO: rm
export def cat-to-tag-id [
    ...c
    --empty-as-all
    --and
] {
    let cond = $in | cat-to-cond --empty-as-all=$empty_as_all 'c.name' 't.name'
    let cond = if ($cond | is-empty) { 'true' } else { $cond }
    let s = [...$c, 't.id'] | str join ', '
    $"select ($s) from tag as t join category as c on t.category_id = c.id where ($cond)"
}

export def dbg [switch content -t:string] {
    if $switch {
        print $"(ansi grey)($t)│($content)(ansi reset)"
    }
}

export def db-upsert [table pk --do-nothing] {
    let r = $in
    let d = if $do_nothing { 'NOTHING' } else {
        $"UPDATE SET ($r| items {|k,v | $"($k)=(Q $v)" } | str join ',')"
    }
    run $"
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
