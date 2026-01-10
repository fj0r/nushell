export def is-binary-file [] {
    $in | first 512 | bytes index-of 0x[00] | $in >= 0
}

export def verify-integrity [fmt] {
    let n: binary = $in
    match $fmt {
        'jpg' | 'jpeg' => {
            $n | last 2 | $in == 0x[ff d9]
        }
        'webp' => {
            $n | bytes at 4..7 | into int | $in + 8 | $in == ($n | length)
        }
    }
}

# new dir and then cd
export def --env nd [
    dir
    --surrfix(-s)="--"
    --temp(-t)
] {
    let dir = $dir | into string
    let dir = if not $temp {
        $dir
    } else {
        $"($surrfix)($dir)($surrfix)" | path expand
    }
    mkdir $dir
    cd $dir
    if $temp {
        $env.config.hooks.env_change.PWD ++= [
            {
                condition: {|before, after| $before == $dir }
                code: $"rm -rf ($dir)"
            }
        ]
    }
}

export def cptree [
    source
    target
    --glob(-g): glob = **/*
] {
    mkdir $target
    let target = $env.PWD | path join $target
    cd $source
    print $env.PWD
    ls ($glob | into glob)
    | get name
    | each {|x|
        let d = $target | path join ($x | path parse | get parent)
        mkdir $d
        cp -v -r $x $d
    }
}
