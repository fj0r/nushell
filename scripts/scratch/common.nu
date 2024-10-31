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

export def run [stmt] {
    open $env.SCRATCH_DB | query db $stmt
}

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

const typemap = {
    md: "# "
    nu: "# "
    py: "# "
    rs: "// "
    js: "// "
    ts: "// "
    hs: "-- "
    sql: "-- "
    lua: "-- "
}

export def 'to title' [type] {
    $in | str replace ($typemap | get $type) ''
}

export def 'from title' [type] {
    $"($typemap | get $type)($in)"
}

export def exec [type] {
    let o = $in
    match $type {
        nu => { nu -c $o --stdin }
        _ => { $o }
    }
}
