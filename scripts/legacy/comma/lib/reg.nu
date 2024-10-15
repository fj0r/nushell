def build [idx obj path val] {
    if ($path | length) > 1 {
        let new_path = $path | range 1..
        let x = if $path.0 in $obj {
            let o = $obj | get $path.0
            if $idx.sub in $o {
                let n = build $idx ($o | get $idx.sub) $new_path $val
                $o | upsert $idx.sub {|| $n }
            } else {
                build $idx $o $new_path $val
            }
        } else {
            build $idx {} $new_path $val
        }
        $obj | merge { ($path.0): $x }
    } else {
        $obj | insert $path.0 {|| $val }
    }
}

def ah [path] {
    let path = if ($path | describe -d).type == list {
        $path
    } else {
        $path | str trim | split row -r '\s+'
    }
    let idx = $env.comma_index
    { path: $path, idx: $idx }
}

export def --env node [path opts] {
    let x = ah $path
    let opts = $opts
    | transpose k v
    | reduce -f {} {|i,a|
        $a | merge { ($x.idx | get $i.k): ($i.v) }
    }
    let o = if ($env.comma | describe -d).type == 'closure' {
        do $env.comma $x.idx
    } else {
        $env.comma
    }
    let c = build $x.idx $o $x.path {
        $x.idx.sub: {}
        ...$opts
    }
    $env.comma = $c
}

export def --env action [path action opts?] {
    let x = ah $path
    let opts = if ($opts | is-empty) {{}} else {
        $opts | transpose k v
        | reduce -f {} {|i,a|
            let v = if ($i.v | describe -d).type == 'closure' {
                {|a,s| do $i.v $a $s $x.idx}
            } else {
                $i.v
            }
            $a | merge { ($x.idx | get $i.k): $v }
        }
    }
    let o = if ($env.comma | describe -d).type == 'closure' {
        do $env.comma $x.idx
    } else {
        $env.comma
    }
    let c = build $x.idx $o $x.path {
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
    $env.comma_scope = (build $x.idx $o $x.path $val)
}

