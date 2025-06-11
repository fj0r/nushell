def cmpl-mod [] {
    $env.manifest | get to
}

export def 'dump nu_scripts' [...mod:string@cmpl-mod --reverse(-r)] {
    use git *
    use git/shortcut.nu *
    use lg
    let m = $env.manifest | where {|x| not ($x.disable? | default false) }
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
    if $act == 'pre-commit' and $ctx.branch == 'main' {
        gen README
        git add .
    }
    if $act == 'pre-push' and $ctx.branch == 'main' {
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
    ^$env.CNTRCTL run ...[
        --name test-nu
        --rm -it
        -v $"($env.PWD):/etc/nushell"
    ] io:x
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
    const p = path self .
    print $p
}

export def 'update todo' [] {
    let m = [todo llm scratch]
    for i in ($env.manifest | where from in $m)  {
        let f = [scripts $i.from TODO.md] | path join
        tl $"proj:($i.to)" -m | save -f $f
    }
}

export def 'git commit scratch' [scratch_id] {
    scommit -f scripts/scratch/TODO.md :proj:scratch -s $scratch_id
}

export def 'gen README' [] {
    open __.toml
    | get manifest
    | where { $in.title? | is-not-empty }
    | sort-by rank
    | each {|x|
        let dist = [scripts $x.from] | path join
        let readme = [$dist README.md] | path join
        let desc = if ($readme | path exists) {
            let t = open $readme | lines | first | parse -r '# (?<title>.*)'
            if ($t | is-empty) { [] } else { $t.title }
        } else {
            []
        }
        let dist = if ($readme | path exists) { $readme } else { $dist }
        let url = if ($x.to? | is-empty) or ($x.disable? | default false) {
            $dist
        } else {
            $"https://github.com/fj0r/($x.to).nu"
        }
        let title = $"- [($x.title)]\(($url)\)"
        [$title ...$desc] | str join ' '
    }
    | str join (char newline)
    | save -f README.md
}
