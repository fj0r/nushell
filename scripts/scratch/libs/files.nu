use db.nu *

def cmpl-kind [] {
    sqlx $"select name from kind" | get name
}

export def scratch-files-import [x] {
    sqlx $"insert into kind_file \(kind, parent, stem, extension, body\) values \(
        (Q $x.kind), (Q $x.parent), (Q $x.stem), (Q $x.extension), (Q $x.body)
    \) on conflict \(kind, parent, stem, extension\) do update set
        kind=EXCLUDED.kind, parent = EXCLUDED.parent, stem=EXCLUDED.stem,
        extension=EXCLUDED.extension, body=EXCLUDED.body
    "
}

export def scratch-files-export [kind: string@cmpl-kind] {
    sqlx $"select * from kind_file where kind = (Q $kind)"
}

export def scratch-files-save [
    kind: string
    dir: string='.'
] {
    cd $dir
    let lst = ls **/* | where type == 'file'
    for f in $lst {
        let c = open --raw $f.name
        let c = $c | to z64
        let x = $f.name | path parse
        scratch-files-import {body: $c, ...$x}
    }
}

export def scratch-files-load [
    kind: string@cmpl-kind
    dir: string="."
] {
    cd $dir
    let files = scratch-files-export $kind
    for f in $files {
        if ($f.parent | is-not-empty) and ($f.parent != '.') {
            if not ($f.parent | path exists) {
                mkdir $f.parent
            }
        }
        let p = $f | select parent stem extension | path join
        $f.body | from z64 | save -f $p
    }
}

export def 'to z64' [] {
    $in | to msgpackz | encode base64
}

export def 'from z64' [] {
    $in | decode base64 | from msgpackz
}

