export use edit.nu *
export use db.nu *
export use str.nu *
export use time.nu *


export def get-config [kind] {
    run $"select * from kind where name = (Q $kind)" | first
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

export def cmpl-kind [] {
    run $"select name from kind" | get name
}
