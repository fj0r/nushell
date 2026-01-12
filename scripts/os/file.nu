export def is-binary-file []: binary -> bool {
    $in | first 512 | bytes index-of 0x[00] | $in >= 0
}

export def verify-integrity [fmt: string]: binary -> bool {
    let n = $in
    match $fmt {
        'jpg' | 'jpeg' => {
            $n | last 2 | $in == 0x[ff d9]
        }
        'webp' => {
            $n | bytes at 4..7 | into int | $in + 8 | $in == ($n | length)
        }
    }
}

export def with-cd [path act --yes(-y)] {
    if not ($path | path exists) {
        if $yes or ([y n] | input list $"create dir ($path)?") == 'y' {
            mkdir $path
        } else {
            return
        }
    }
    let old = $env.PWD
    cd $path
    do $act $path $old
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
