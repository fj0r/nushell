def build [obj path val] {
    if ($path | length) > 1 {
        let n = if $path.0 in $obj { $obj | get $path.0 } else { {} }
        $obj | merge { ($path.0): (build $n ($path | range 1..) $val) }
    } else {
        $obj | insert $path.0 {|| $val }
    }
}

def ah [path] {
    let path = if ($path | describe -d).type == list {
        $path
    } else {
        $path | split row -r '\s+'
    }
    let idx = $env.comma_index
    { path: $path, idx: $idx }
}

export def --env action [path action opts?] {
    let x = ah $path
    let opts = if ($opts | is-empty) {{}} else {
        $opts | transpose k v
        | reduce -f {} {|i,a|
            $a | merge { ($x.idx | get $i.k): ($i.v) }
        }
    }
    let o = if ($env.comma | describe -d).type == 'closure' {
        do $env.comma $x.idx
    } else {
        $env.comma
    }
    let c = build $o $x.path {
        $x.idx.action: {|a,s| do $action $a $s $x.idx }
        ...$opts
    }
    $env.comma = $c
}

export def --env scope [path type val] {
    let x = ah $path
    let val = if ($type | is-empty) {
        $val
    } else {
        { ($x.idx | get $type): ({|a,s,m| do $val $a $s $m $x.idx }) }
    }
    let o = if ($env.comma_scope | describe -d).type == 'closure' {
        do $env.comma_scope $x.idx
    } else {
        $env.comma_scope
    }
    $env.comma_scope = (build $o $x.path $val)
}

