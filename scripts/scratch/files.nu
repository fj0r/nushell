use libs/db.nu *

export def scratch-files-save [kind, dir: string='.'] {
    cd $dir
    let lst = ls **/* | where type == 'file'
    for f in $lst {
        let c = open --raw $f.name
        let hash = $c | hash sha256
        let c = $c | to z64
        let x = $f.name | path parse
        sqlx $"insert into kind_file \(kind, hash, path, name, ext\) values \(
            (Q $kind), (Q $hash), (Q $x.parent), (Q $x.stem), (Q $x.extension)
        \) on conflict \(kind, path, name, ext\) do update set
            kind = EXCLUDED.kind, hash = EXCLUDED.hash,
            path = EXCLUDED.path, name = EXCLUDED.name, ext = EXCLUDED.ext
        "
        sqlx $"insert into file \(hash, body\) values \(
            (Q $hash), (Q $c)
        \) on conflict \(hash\) do nothing"
    }
}

export def scratch-files-load [kind, dir: string="."] {
    cd $dir
    let files = sqlx $"select k.path, k.name, k.ext, f.body from kind_file as k
        join file as f on k.hash = f.hash where k.kind = (Q $kind)"
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
