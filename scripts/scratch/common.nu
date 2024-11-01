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

export def table-upsert [config] {
    let d = $in
    let d = $config.default | merge $d
    $config.default
    | columns
    | reduce -f {} {|i,a|
        let x = $d | get $i
        let x = if ($i in $config.filter) {
            $x | do ($config.filter | get $i) $x
        } else {
            $x
        }
        $a | insert $i $x
    }
    | db-upsert --do-nothing $config.table $config.pk
}

export def add-type [] {
    $in | table-upsert {
        default: {
            name: 'md'
            comment: "# "
            runner: 'file'
            cmd: ''
        }
        table: type
        pk: name
        filter: {}
    }
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

export def render [scope: record] {
    let tmpl = $in
    $scope
    | transpose k v
    | reduce -f $tmpl {|i,a|
        let k = if $i.k == '_' { '' } else { $i.k }
        $a | str replace --all $"{($k)}" ($i.v | into string)
    }
}

export def get-config [type] {
    run $"select * from type where name = (Q $type)" | first
}

export def 'to title' [config] {
    $in | str replace ($config.comment) ''
}

export def 'from title' [config] {
    $"($config.comment)($in)"
}

def remove-file [...fs] {
    for f in $fs {
        if ($f | is-not-empty) {
            rm -f $f
        }
    }
}

export def performance [config stdin?=''] {
    let f = $in | maketemp $'scratch-XXX.($config.name)'
    let i = $stdin | maketemp $'scratch-XXX.stdin'
    match $config.runner {
        'file' => {
            nu -c ($config.cmd | render {_: $f, stdin: $i})
            remove-file $f $i
        }
        'dir' => {
            remove-file $f $i
        }
        'remote' => {
            rm -f $f $i
        }
        _ => {
            let o = open $f
            remove-file $f $i
            $o
        }
    }
}

export def cmpl-type [] {
    run $"select name from type" | get name
}
