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

export def not-subpath [p] {
    let sub = $in
    do -i { $sub | path relative-to ($p) } | default '' |  is-empty
}

# new dir and then cd
export def --env nd [
    dir
    --surrfix(-s)="__"
    --temp(-t)
] {
    let dir = $dir | into string
    let dir = if not $temp {
        $dir
    } else {
        let d = $dir | path expand | path split
        $d | slice ..-2 | path join $"($surrfix)($d | last)($surrfix)" | path join
    }

    mkdir $dir
    use std/dirs
    dirs add $dir
    if $temp {
        use nushell.nu self-destruct-hook
        $env.config.hooks.env_change.PWD ++= [
            {
                nd-destruct: $dir
                condition: {|before, after| $after != $dir and ($after | not-subpath $dir) }
                code: (
                    $"
                    print $'\(ansi grey\)clean temp dir: `($dir)`\(ansi reset\)'
                    rm -rf ($dir)
                    (self-destruct-hook env_change.PWD nd-destruct $dir)
                    "
                    | str trim
                    | str replace -rma '^ {20}' ''
                )
            }
        ]
    }
}

export def into-tree [target: path, --cwd(-c): path]: list<string> -> nothing  {
    let n = $in
    let target = $target | path expand
    mkdir $target
    if ($cwd | is-not-empty) {
        cd $cwd
    }
    for x in $n {
        let d = $target | path join ($x | path parse | get parent)
        if not ($d | path exists) {
            mkdir $d
        }
        cp -r -v $x $d
    }
}
