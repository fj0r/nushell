export def --env 'project init-git-hooks' [] {
    $env.GIT_HOOKS = {
        # commit
        pre-commit: {type: commit, default: true}
        pre-merge-commit: {type: commit, default: true}
        prepare-commit-msg: {type: commit, default: true}
        commit-msg: {type: commit, default: true}
        post-commit: {type: commit, default: true}
        # email
        applypatch-msg: {type: email}
        pre-applypatch: {type: email}
        post-applypatch: {type: email}
        # client
        pre-rebase: {type: client}
        post-rewrite: {type: client}
        post-checkout: {type: client}
        post-merge: {type: client}
        pre-push: {type: client, default: true}
        pre-auto-gc: {type: client}
        push-to-checkout: {type: client}
        reference-transaction: {type: client}
        # server
        pre-receive: {type: server}
        update: {type: server}
        post-update: {type: server}
        post-receive: {type: server}

        fsmonitor-watchman: {type: other}
    }
}

def git-cdup [] {
    let r = git rev-parse --show-cdup | complete
    if $r.exit_code == 0 {
        $r.stdout | str trim
    }
}

def git-commit [] {
    let c = git log --reverse -n 1 --pretty=%h»¦«%s
    | split row '»¦«'
    {
        hash: $c.0
        message: $c.1
    }
}

def git-current-branch [] {
    git rev-parse --abbrev-ref HEAD
}

export def git-list-hooks [] {
    let c = git-cdup
    if ($c | describe) == nothing { return }
    let hp = [$c .git hooks] | path join
    ls $hp | get name | path parse
    | filter {|x| ($x.extension | is-empty) and ($x.stem in $env.GIT_HOOKS) }
    | get stem
}

def cmpl-hooks [] {
    $env.GIT_HOOKS | columns
}

export def git-uninstall-hooks [...hooks:string@git-list-hooks] {
    let c = git-cdup
    if ($c | describe) == nothing { return }
    let hp = [$c .git hooks] | path join
    let hs = if ($hooks | is-empty) { git-list-hooks } else { $hooks }
    for h in $hs {
        rm -f ([$hp $h] | path join)
    }
}

export def has-git-hooks [mod fun] {
    scope commands
    | where name == $'($mod) ($fun)'
    | is-not-empty
}

export def git-hooks-dir [] {
    $env.CURRENT_FILE
    | path split
    | split list '.git'
    | range ..<-1
    | flatten
    | path join
}

export def git-hooks-context [] {
    let argv = $in
    {
        workdir: $env.PWD
        ...(git-commit)
        remote: $argv.0?
        repo: $argv.1?
        branch: (git-current-branch)
    }
}

export def git-install-hooks [
    ...hooks:string@cmpl-hooks
    --mod(-m)="__"
    --fun(-f)="git-hooks"
] {
    let c = git-cdup
    if ($c | describe) == nothing { return }
    let hook_path = [$c .git hooks] | path join
    #let workdir = [$env.PWD $c] | path join | path expand
    let hs = $env.GIT_HOOKS | transpose k v
    let hs = if ($hooks | is-empty) { $hs | filter {$in.v.default?} } else { $hs | where k in $hooks }
    for h in $hs {
        let p = [$hook_path $h.k] | path join
        $"_: |-
        #!/bin/env nu
        use project
        use ../../($mod).nu

        export def main [...argv: string] {
            if \(project has-git-hooks ($mod) ($fun)\) {
                let wd = project git-hooks-dir
                cd $wd
                project direnv ($mod)
                ($mod) ($fun) '($h.k)' \($argv | project git-hooks-context\)
            } else {
                print $'\(ansi grey\)($h.k): `($fun)` function is undefined.\(ansi reset\)'
            }
        }
        "
        | from yaml | get _
        | save -f $p
        chmod +x $p
    }
}
