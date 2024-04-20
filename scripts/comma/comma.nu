def build [obj path val] {
    if ($path | length) > 1 {
        let n = if $path.0 in $obj { $obj | get $path.0 } else { {} }
        $obj | upsert $path.0 (build $n ($path | range 1..) $val)
    } else {
        $obj | insert $path.0 $val
    }
}

def ah [key path] {
    let path = if ($path | describe -d).type == list {
        $path
    } else {
        $path | split row -r '\s+'
    }
    let idx = $env.comma_index
    let oc = if ($env | get $key | describe -d).type == 'closure' {
        do ($env | get $key) $idx
    } else {
        $env | get $key
    }
    { path: $path, idx: $idx, origin: $oc }
}

export def --env action [path action opts?] {
    let x = ah comma $path
    let opts = if ($opts | is-empty) {{}} else {
        $opts | transpose k v
        | reduce -f {} {|i,a|
            $a | merge { ($x.idx | get $i.k): ($i.v) }
        }
    }
    $env.comma = (
        build $x.origin $x.path {
            $x.idx.action: {|a,s|
                do $action $a $s $x.idx
            }
            ...$opts
        }
    )
}

export def --env scope [path action opts?] {
    let x = ah comma_scope $path
}


