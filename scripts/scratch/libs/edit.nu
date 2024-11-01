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

export def maketemp [tmp] {
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
