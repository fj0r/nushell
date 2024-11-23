def cmpl-mod [] {
    $env.manifest | get to
}

export def 'dump nu_scripts' [...mod:string@cmpl-mod --reverse(-r)] {
    use git *
    use git/shortcut.nu *
    use lg
    let m = $env.manifest | filter {|x| not ($x.disable? | default false) }
    let m = if ($mod | is-empty) { $m } else {
        $m | where to in $mod
    }
    let o = $"($env.PWD)/scripts"
    lg level 1 'begin'
    for x in $m {
        lg level 0 $"($x.to).nu"
        let t0 = $'($env.dest)/($x.to)'
        if ($t0 | path exists | not $in) { mkdir $t0 }
        let t = [$t0 $x.to] | path join
        if $reverse {
            cd $t
            gp
            git-sync $t $'($o)/($x.from)'
        } else {
            (git-sync
                $'($o)/($x.from)' $t
                --push
                --init=$"git@github-fjord:fj0r/($x.to).nu.git"
                --post-sync {|src, desc|
                    cd $desc
                    let md = ls | get name | path parse | where extension == 'md'
                    for m in $md {
                        mv -f $"($m.stem).($m.extension)" ..
                    }
                    cd ..
                    ga
                }
            )
        }
    }
    lg level 1 'end'
}

export def git-hooks [act ctx] {
    if $act == 'pre-push' and $ctx.branch == 'dev' {
        if $ctx.repo == 'git@github-fjord:fj0r/nushell.git' {
            dump nu_scripts
        }
    }
    if $act == 'fsmonitor-watchman' {
        print $act
    }
    if false {
        use lg
        lg msg {act: $act, ...$ctx}
    }
}

export def 'test in container' [] {
    ^$env.CONTCTL run ...[
        --name test-nu
        --rm -it
        -v $"($env.PWD):/etc/nushell"
    ] io:hs
}

export def 'add nupm.nuon' [] {
    for d in $env.manifest {
        cd $env.dest
        let d = $d.to
        if ([$d nupm.nuon] | path join | path exists) or not ([$d .git] | path join | path exists) {
            continue
        }
        lg level 1 $d
        mv $d _
        mkdir $d
        mv $"_/.git" $d
        mkdir $"($d)/($d)"
        mv ("_/*" | into glob) $"($d)/($d)"
        rm _
        let m = {
          "name": $d
          "version": "1.0.0"
          "description": ""
          "maintainers": ["@fj0r"]
          "type": "module"
          "license": "MIT License"
        } | to nuon -i 2
        $m | save $"($d)/nupm.nuon"
        cd $d
        ga
        gc 'Package for nupm'
        gp
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

export def 'update todo' [] {
    let m = [todo llm scratch]
    for i in ($env.manifest | where from in $m)  {
        let f = [scripts $i.from TODO.md] | path join
        tl $"proj:($i.to)" -m | save -f $f
    }
}
