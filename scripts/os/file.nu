export def is-text-file [$f] {
    open -r $f | into binary | first 512 | bytes index-of 0x[00] | $in < 0
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
