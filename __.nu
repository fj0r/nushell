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


export def 'export nu_scripts' [...mod:string@cmpl-mod] {
    let m = $manifest | filter {|x| not ($x.disable? | default false) }
    let m = if ($mod | is-empty) { $m } else {
        $m | where to in $mod
    }
    let l = git-last-commit
    let o = $"($env.PWD)/scripts"
    for x in $m {
        print $"(ansi yellow)### ($x.to).nu(ansi reset)"
        let t = $'($env.dest)/($x.to)'
        if ($t | path exists | not $in) { mkdir $t }
        rsync -avP --delete $'($o)/($x.from)' --exclude='.git'  $t
        cd $t
        if not (git-is-repo) {
            git-init $"git@github-fjord:fj0r/($x.to).nu.git"
            gp
        } else {
            if (git-changes | is-not-empty) {
                ga .
                gc $l.message
                gp
            } else {
                $"(ansi yellow)($x.to)(ansi reset) no changes"
            }
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
