const manifest = [
    { from: argx/, to: argx }
    { from: ssh/, to: ssh }
    { from: docker/, to: docker }
    { from: devcontainer/, to: devcontainer }
    { from: kubernetes/, to: kubernetes }

    { from: lg/, to: lg }
    { from: todo/, to: todo }
    { from: git/, to: git }
    { from: llm/, to: ai }

    { from: nvim/, to: nvim, disable: true }

    { from: power/, to: powerline, disable: false }
    { from: cwdhist/, to: cwdhist }
    { from: history-utils/, to: history-utils, disable: true}
    { from: resolvenv/, to: resolvenv, disable: true }

    { from: project/, to: project }
]

export-env {
    $env.dest = [$env.HOME world nu_scripts] | path join
}

def cmpl-mod [] {
    $manifest | get to
}

export def 'dump nu_scripts' [...mod:string@cmpl-mod] {
    use git *
    use git/shortcut.nu *
    use lg
    let m = $manifest | filter {|x| not ($x.disable? | default false) }
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
        git-sync $'($o)/($x.from)' $t --push --init=$"git@github-fjord:fj0r/($x.to).nu.git"
    }
    lg level 1 'end'
}

export def git-hooks [x args] {
    if $x == 'pre-push' {
        if $args.1 == 'git@github-fjord:fj0r/nushell.git' {
            dump nu_scripts
        }
    }
}

export def replace-cmpl [file --dry-run] {
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
