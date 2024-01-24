export def gendict [size extend] {
    let keys = $in
    mut k = []
    let n = $keys | length
    let rk = random chars -l ($n * $size)
    for i in 1..$n {
        let b = ($i - 1) * $size
        let e = $i * $size
        $k ++= ($rk | str substring $b..$e)
    }
    let ids = $keys
    | zip $k
    | reduce -f {} {|x, acc|
        let id = if ($x.0 | describe -d).type == 'list' { $x.0 } else { [$x.0] }
        $id | reduce -f $acc {|i,a| $a | insert $i $"($id.0)_($x.1)" }
    }
    $extend
    | transpose k v
    | reduce -f $ids {|x, acc|
        $acc | insert $x.k { $x.v }
    }
}


export def distro [] {
    match $nu.os-info.name {
        'linux' => {
            let info = cat /etc/os-release
            | lines
            | reduce -f {} {|x, acc|
                let a = $x | split row '='
                $acc | upsert $a.0 ($a.1| str replace -a '"' '')
            }
            if 'ID_LIKE' in $info {
                if not ($info.ID_LIKE | parse -r '(rhel|fedora|redhat)' | is-empty) {
                    'redhat'
                } else {
                    $info.ID_LIKE
                }
            } else {
                $info.ID
            }
        }
        _ => {
            $nu.os-info.name
        }
    }
}

export def outdent [] {
    let txt = $in | lines | range 1..
    let indent = $txt.0 | parse --regex '^(?P<indent>\s*)' | get indent.0 | str length
    $txt
    | each {|s| $s | str substring $indent.. }
    | str join (char newline)
}
