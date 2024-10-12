def cmpl-mod [] {
    $env.manifest | get to
}

export def 'dump nu_scripts' [...mod:string@cmpl-mod] {
    use git *
    use git/shortcut.nu *
    use lg
    let m = $env.manifest | filter {|x| not ($x.disable? | default false) }
    let m = if ($mod | is-empty) { $m } else {
        $m | where to in $mod
    }
    let l = git-last-commit
    let o = $"($env.PWD)/scripts"
    lg level 1 'begin'
    for x in $m {
        lg level 0 $"($x.to).nu"
        let t = $'($env.dest)/($x.to)'
        if ($t | path exists | not $in) { mkdir $t }
        git-sync $'($o)/($x.from)' ($t | path expand) --push --init=$"git@github-fjord:fj0r/($x.to).nu.git"
    }
    lg level 1 'end'
}

export def git-hooks [act ctx] {
    if $act == 'pre-push' {
        if $ctx.repo == 'git@github-fjord:fj0r/nushell.git' {
            dump nu_scripts
        }
    }
    if $act == 'fsmonitor-watchman' {
        print $act
    }
    if false {
        use lg
        lg msg {act: $act, workdir: $ctx.workdir}
    }
}

export def rename-cmpl-func [file --dry-run] {
    let r = cat $file
    | lines
    | each {|x|
        let rx = "[\"'](?<x>nu-complete.*?)[\"']"
        let rs = $x | parse -r $rx | get -i x
        if ($rs | is-empty) { $x } else {
            mut s = $x
            for r in $rs {
                let a = $r | str replace -a ' ' '-' | str replace 'nu-complete' 'cmpl'
                $s = $s | str replace -r $rx $a
            }
            $s
        }
    }
    | str join (char newline)

    if $dry_run { print $r } else { $r | collect | save -f $file }
}

export def file-pwd [] {
    print $env.FILE_PWD
}
