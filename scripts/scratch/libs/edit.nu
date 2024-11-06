use files.nu *

def variants-edit [file? --line:int] {
    if ($line | is-empty) {
        ^$env.EDITOR $file
    } else {
        if ($env.EDITOR | find vim | is-not-empty) {
            ^$env.EDITOR $"+($line)" $"+normal $" $file
        } else {
            ^$env.EDITOR $file
        }
    }
}

export def mktmpdir [
    tmp
    entry
    --title: string
    --kind: string
    --created
] {
    let body = $in
    let dir = mktemp -d -t $tmp
    let file = [$dir $entry] | path join
    let relative_dir = $entry | path dirname
    if ($relative_dir | is-not-empty) and ($relative_dir != '.') {
        mkdir ($file | path dirname)
    }
    scratch-files-load $kind $dir

    if $created {
        let body = if ($body | is-empty) { $"\n" } else { $"\n<<<<<<< STDIN\n($body)\n=======" }
        let tmpl = if ($file | path exists) {
            open --raw $file
        } else {
            ''
        }
        $"($title)($body)\n($tmpl)" | save -f $file
    } else {
        $"($title)\n($body)" | save -f $file
    }
    {
        file: $file
        dir: $dir
        entry: $entry
    }
}

export def block-project-edit [
    temp: string
    entry: string
    pos: int
    --title: string
    --kind: string
    --created
    --retain
] {
    let content = $in
    let tf = $content | mktmpdir $temp $entry --kind $kind --title $title --created=$created
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


export def block-edit [temp] {
    let content = $in
    let tf = mktemp -t $temp
    $content | save -f $tf
    ^$env.EDITOR $tf
    let c = open $tf --raw
    rm -f $tf
    $c
}
