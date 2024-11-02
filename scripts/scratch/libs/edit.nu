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

export def mktmpdir [tmp entry] {
    let o = $in
    let dir = mktemp -d -t $tmp
    let f = [$dir $entry] | path join
    $o | default '' | save -f $f
    {
        file: $f
        dir: $dir
        entry: $entry
    }
}

export def block-edit [
    temp: string
    entry: string
    cfg: record = {}
    --retain
] {
    let content = $in
    let tf = $content | mktmpdir $temp $entry
    let opwd = $env.PWD
    cd $tf.dir
    variants-edit $tf.file --line $cfg.pos
    let c = open $tf.file --raw
    if not $retain {
        cd $opwd
        rm -rf $tf.dir
    }
    {
        content: $c
        ...$tf
    }
}
