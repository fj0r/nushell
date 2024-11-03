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
    let file = [$dir $entry] | path join
    let relative_dir = $entry | path dirname
    if ($relative_dir | is-not-empty) and ($relative_dir != '.') {
        mkdir ($file | path dirname)
    }

    $o | default '' | save -f $file
    {
        file: $file
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
