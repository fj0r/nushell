export def --env main [mod?:string="__"] {
    let _ = if ('.env' | path exists) {
        open .env
        | lines
        | parse -r '(?<k>.+?)\\s*=\\s*(?<v>.+)'
        | reduce -f {} {|x, acc| $acc | upsert $x.k $x.v}
    }
    | default {}

    [yaml, toml]
    | reduce -f {} {|i,a|
        let f = $'($mod).($i)'
        if ($f | path exists) { $a | merge (open $f) } else { $a }
    }
    | merge $_
    | load-env
}

