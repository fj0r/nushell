use files.nu *

def variants-edit [file? --line:int] {
    if ($line | is-empty) {
        ^$env.EDITOR $file
    } else {
        if ($env.EDITOR | find vim | is-not-empty) {
            ^$env.EDITOR $"+($line)" "+normal $" $file
        } else {
            ^$env.EDITOR $file
        }
    }
}

export def mktmpdir [tmp entry --kind: string] {
    let o = $in
    let dir = mktemp -d -t $tmp
    let file = [$dir $entry] | path join
    let relative_dir = $entry | path dirname
    if ($relative_dir | is-not-empty) and ($relative_dir != '.') {
        mkdir ($file | path dirname)
    }
    scratch-files-load $kind $dir
    # TODO
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
    pos: int
    --kind: string
    --retain
] {
    let content = $in
    let tf = $content | mktmpdir $temp $entry --kind $kind
    let opwd = $env.PWD
    cd $tf.dir
    variants-edit $tf.file --line $pos
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
