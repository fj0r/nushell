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

def maketemp [tmp] {
    let o = $in
    let t = mktemp -t $tmp
    $o | save -f $t
    return $t
}

export def block-edit [
    temp
    --line: int
    --type: string
] {
    let content = $in
    let tf = $content | maketemp $temp
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

def run-file [type runner] {
    let o = $in
    let f = $o | maketemp $'scratch-XXX.($type)'
    ^$runner $f
    rm -f $f
}

export def exec [type] {
    let o = $in
    match $type {
        nu => { $o | run-file nu nu }
        py => { $o | run-file py python3 }
        js => { $o | run-file js node }
        rs => { $o | run-file rs rust-script }
        _ => { $o }
    }
}

export def cmpl-type [] {
    [nu py js rs md]
}
