export def --env main [] {
    let _ = if ('.env' | path exists) {
        open .env
        | lines
        | parse -r '(?<k>.+?)\\s*=\\s*(?<v>.+)'
        | reduce -f {} {|x, acc| $acc | upsert $x.k $x.v}
    }
    | default {}

    [yaml, toml]
    | reduce -f {} {|i,a|
        let f = $'__.($i)'
        if ($f | path exists) { $a | merge (open $f) } else { $a }
    }
    | merge $_
    | load-env
}

