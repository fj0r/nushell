use db.nu *

def cmpl-kind [] {
    sqlx $"select name from kind" | get name
}

export def scratch-files-import [x] {
    sqlx $"insert into kind_file \(kind, hash, parent, stem, extension\) values \(
        (Q $x.kind), (Q $x.hash), (Q $x.parent), (Q $x.stem), (Q $x.extension)
    \) on conflict \(kind, parent, stem, extension\) do update set
        kind=EXCLUDED.kind, hash=EXCLUDED.hash, parent = EXCLUDED.parent,
        stem=EXCLUDED.stem, extension=EXCLUDED.extension
    "
    sqlx $"insert into file \(hash, body\) values \(
        (Q $x.hash), (Q $x.body)
    \) on conflict \(hash\) do nothing"
}

export def scratch-files-export [kind: string@cmpl-kind] {
    sqlx $"select k.kind, k.hash, k.parent, k.stem, k.extension, f.body
        from kind_file as k join file as f on k.hash = f.hash where k.kind = (Q $kind)"
}

export def scratch-files-save [
    kind: string
    dir: string='.'
] {
    cd $dir
    let lst = ls **/* | where type == 'file'
    for f in $lst {
        let c = open --raw $f.name
        let hash = $c | hash sha256-base64
        let c = $c | to z64
        let x = $f.name | path parse
        scratch-files-import {kind: $kind, body: $c, hash: $hash, ...$x}
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

export def 'hash sha256-base64' [] {
    $in | hash sha256 | decode hex | encode base64
}

export def 'to z64' [] {
    $in | to msgpackz | encode base64
}

export def 'from z64' [] {
    $in | decode base64 | from msgpackz
}

export def scratch-files-gc [] {
    sqlx $"delete from file where hash not in \(
        select hash from kind_file
    \) returning hash"
}
