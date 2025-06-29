use argx

export def mc-alias [] {
    ^mc alias ls --json | from json -o | get alias
}

export def mc-subkey [] {
    let key = $in
    if ($key | is-empty) {
        mc-alias
    } else {
        mc-ls $key
        | where {|x| $x.type == 'dir'}
        | get key
        | each {|x|
            [$key $x] | path join
        }
    }
}

def gen-cmpl [key] {
    $in | argx parse | get ($key | into cell-path) | mc-subkey
}

export def 'nu-cmp mc-src' [context: string] {
    $context | gen-cmpl [pos src]
}

export def 'nu-cmp mc-dest' [context: string] {
    $context | gen-cmpl [pos dest]
}

export def mc-ls [
    src: string@'nu-cmp mc-src'
] {
    ^mc ls $src --json
    | from json -o
    | update lastModified {|x| $x.lastModified | into datetime }
    | update type {|x|
        match $x.type {
            folder => 'dir',
            _ => $x.type
        }
    }
}

export def mc-mv [
    src: string@'nu-cmp mc-src'
    dest: string@'nu-cmp mc-dest'
] {
    ^mc mv $src $dest
}

export def mc-cp [
    src: string@'nu-cmp mc-src'
    dest: string@'nu-cmp mc-dest'
] {
    ^mc cp $src $dest
}

export def mc-put [
    src: string
    dest: string@'nu-cmp mc-dest'
] {
    ^mc put $src $dest
}
