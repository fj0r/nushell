def agree [prompt] {
    let prompt = if ($prompt | str ends-with '!') {
        $'(ansi red)($prompt)(ansi reset)'
    } else {
        $'($prompt)'
    }
    ([yes no] | input list $prompt) in [yes]
}

def sprb [flag, args] {
    if $flag {
        $args
    } else {
        []
    }
}

def spr [args] {
    let lst = ($args | last)
    if ($lst | is-empty) {
        []
    } else {
        let init = ($args | range ..-2)
        if ($init | is-empty) {
            [ $lst ]
        } else {
            $init | append $lst
        }
    }
}

# git status and stash
export def gs [
    --apply (-a):             bool
    --clear (-c):             bool
    --drop (-d):              bool
    --list (-l):              bool
    --pop (-p):               bool
    --show (-s):              bool
    --all (-A):               bool
    --include-untracked (-i): bool
] {
    if $apply {
        git stash apply
    } else if $clear {
        git stash clear
    } else if $drop {
        git stash drop
    } else if $list {
        git stash list
    } else if $pop {
        git stash pop
    } else if $show {
        git stash show --text
    } else if $all {
        git stash --all (sprb $include_untracked [--include-untracked])
    } else {
        git status
    }
}

# git log
export def gl [
    commit?: string@"nu-complete git log"
    --verbose(-v):bool
    --num(-n):int=32
] {
    if ($commit|is-empty) {
        _git_log $verbose $num
    } else {
        git log --stat -p -n 1 $commit
    }
}

# git branch
export def gb [
    branch?:          string@"nu-complete git branches"
    --delete (-d):    bool
    --remote (-r):    bool
    --no-merged (-n): bool
] {
    let bs = (git branch | lines | each {|x| $x | str substring 2..})
    if ($branch | is-empty) {
        if $remote {
            git branch --remote
        } else if $no_merged {
            git branch --no-merged
        } else {
            git branch
        }
    } else if $branch in $bs {
        if $delete {
            if (agree 'branch will be delete!') {
                git branch -D $branch
            }
            if $branch in (remote_braches | each {|x| $x.1}) and (agree 'delete remote branch?!') {
                git push origin -d $branch
            }
        } else {
            git checkout $branch
        }
    } else {
        if (agree 'create new branch?') {
            git checkout -b $branch
        }
    }
}

# git clone, init
export def-env gn [
    repo?:            string@"nu-complete git branches"
    local?:           path
    --submodule (-s): bool     # git submodule
    --init (-i):      bool     # git init
] {
     if $init {
        git init $repo
        cd $repo
        if $submodule {
            git submodule init
        }
    } else {
        let local = if ($local | is-empty) {
            $repo | path basename | split row '.' | get 0
        } else {
            $local
        }
        git clone (sprb $submodule [--recurse-submodules]) $repo $local
        cd $local
    }
}

# git pull, push and switch
export def gp [
    branch?:             string@"nu-complete git remote branches"
    remote?:             string@"nu-complete git remote branches"
    --force (-f):        bool     # git push -f
    --override:          bool
    --submodule (-s):    bool     # git submodule
    --init (-i):         bool     # git init
    --rebase (-r):       bool     # git pull --rebase
    --autostash (-a):    bool     # git pull --autostash
] {
    if $submodule {
        git submodule update
    } else if $override {
        git pull
        git add --all
        git commit -v -a --no-edit --amend
        git push --force
    } else {
        let r = (sprb $rebase [--rebase])
        let a = (sprb $autostash [--autostash])
        let branch = if ($branch | is-empty) { (_git_status).branch } else { $branch }
        let lbs = (git branch | lines | each {|x| $x | str substring 2..})
        let rbs = (remote_braches | each {|x| $x.0})
        if $branch in $rbs {
            if $branch in $lbs {
                let bmsg = 'both local and remote have the branch'
                if $force {
                    print '($bmsg), with --force, push'
                    git push --force
                } else {
                    print $'($bmsg), pull'
                    if (_git_status).branch != $branch {
                        print $'switch to ($branch)'
                        git checkout $branch
                    }
                    git pull $r $a -v
                }
            } else {
                print "local doesn't have that branch, fetch"
                let remote = if ($remote|is-empty) { 'origin' } else { $remote }
                git checkout -b $branch
                git fetch $remote $branch
                git branch -u $'($remote)/($branch)' $branch
                git pull
            }
        } else {
            let bmsg = "remote doesn't have that branch"
            let force = (sprb $force [--force])
            let remote = if ($remote|is-empty) { 'origin' } else { $remote }
            if $branch in $lbs {
                print $'($bmsg), set upstream and push'
                git checkout $branch
            } else {
                print $'($bmsg), create and push'
                git checkout -b $branch
            }
            git push $force --set-upstream $remote $branch
        }

        let s = (_git_status)
        if $s.ahead > 0 {
            print 'remote is behind, push'
            git push
        }
    }
}

# git add, rm and restore
export def ga [
    file?:          path
    --all (-A):     bool
    --patch (-p):   bool
    --update (-u):  bool
    --verbose (-v): bool
    --delete (-d):  bool    # git rm
    --cached (-c):  bool
    --force (-f):   bool
    --restore (-r): bool    # git restore
    --staged (-s):  bool
    --source (-o):  string
] {
    if $delete {
        let c = (sprb $cached [--cached])
        let f = (sprb $force [--force])
        git rm $c $f $file
    } else if $restore {
        let o = (spr [--source $source])
        let s = (sprb $staged [--staged])
        let file = if ($file | is-empty) { [.] } else { [$file] }
        git restore $o $s $file
    } else {
        let a = (sprb $all [--all])
        let p = (sprb $patch [--patch])
        let u = (sprb $update [--update])
        let v = (sprb $verbose [--verbose])
        let file = if ($file | is-empty) { [.] } else { [$file] }
        git add $a $p $u $v $file
    }

}

# git commit
export def gc [
    --message (-m): string
    --all (-A):     bool
    --amend (-a):   bool
    --keep (-k):    bool
] {
    let m = (spr [-m $message])
    let a = (sprb $all [--all])
    let n = (sprb $amend [--amend])
    let k = (sprb $keep [--no-edit])
    git commit -v $m $a $n $k
}

# git diff
export def gd [
    file?:            path
    --cached (-c):    bool # cached
    --word-diff (-w): bool # word-diff
    --staged (-s):    bool # staged
] {
    let w = (sprb $word_diff [--word-diff])
    let c = (sprb $cached [--cached])
    let s = (sprb $staged [--staged])
    git diff $c $s $w (spr [$file])
}

# git merge
export def gm [
    branch?:            string@"nu-complete git branches"
    --abort (-a):       bool
    --continue (-c):    bool
    --quit (-q):        bool
    --squash (-s):      bool
] {
    let x = (sprb $squash [--squash])
    if ($branch | is-empty) {
        git merge $x $"origin/(git_main_branch)"
    } else {
        git merge $x $branch
    }
}

# git rebase
export def gr [
    branch?:            string@"nu-complete git branches"
    --interactive (-i): bool
    --onto (-o):        string
    --abort (-a):       bool
    --continue (-c):    bool
    --skip (-s):        bool
    --quit (-q):        bool
] {
    if $abort {
        git rebase --abort
    } else if $continue {
        git rebase --continue
    } else if $skip {
        git rebase --skip
    } else if $quit {
        git rebase --quit
    } else if $onto {
        git rebase --onto $branch
    } else {
        let i = (sprb $interactive [--interactive])
        if ($branch | is-empty) {
            git rebase $i (git_main_branch)
        } else {
            git rebase $i $branch
        }
    }
}

# git cherry-pick
export def gcp [
    commit?:         string@"nu-complete git log"
    --abort (-a):    bool
    --continue (-c): bool
    --skip (-s):     bool
    --quit (-q):     bool
] {
    if $abort {
        git cherry-pick --abort
    } else if $continue {
        git cherry-pick --continue
    } else if $skip {
        git cherry-pick --skip
    } else if $quit {
        git cherry-pick --quit
    } else {
        git cherry-pick $commit
    }
}

# git reset
export def grs [
    commit?:      string@"nu-complete git log"
    --hard (-h):  bool
    --clean (-c): bool
] {
    let h = (sprb $hard [--hard])
    let cm = (spr [$commit])
    git reset $h $cm
    if $clean {
        git clean -fxd
    }
}


# git remote
export def grm [
    remote?:       string@"nu-complete git remotes"
    uri?:          string
    --add (-a):    bool
    --rename (-r): bool
    --delete (-d): bool
    --update (-u): bool
    --set (-s):    bool
] {
    if ($remote | is-empty) {
        git remote -v
    } else if $add {
        git remote add $remote $uri
    } else if $set {
        git remote set-url $remote $uri
    } else if $rename {
        let old = $remote
        let new = $uri
        git remote rename $old $new
    } else if $delete {
        git remote remove $remote
    } else if $update {
        git remote update $remote
    } else {
        git remote show $remote
    }
}

# git bisect
export def gbs [
    --bad (-b):   bool
    --good (-g):  bool
    --reset (-r): bool
    --start (-s): bool
] {
    if $good {
        git bisect good
    } else if $bad {
        git bisect bad
    } else if $reset {
        git bisect reset
    } else if $start {
        git bisect start
    } else {
        git bisect
    }
}

export def gha [] {
    git log --pretty=%h»¦«%aN»¦«%s»¦«%aD
    | lines
    | split column "»¦«" sha1 committer desc merged_at
    | histogram committer merger
    | sort-by merger
    | reverse
}

export def ggc [] {
    git reflog expire --all --expire=now
    git gc --prune=now --aggressive
}

export alias gcf = git config --list
export alias gsw = git switch
export alias gswc = git switch -c
export alias gts = git tag -s

export def _git_status [] {
    let raw_status = (do -i { git --no-optional-locks status --porcelain=2 --branch | lines })

    mut status = {
        idx_added_staged    : 0
        idx_modified_staged : 0
        idx_deleted_staged  : 0
        idx_renamed         : 0
        idx_type_changed    : 0
        wt_untracked        : 0
        wt_modified         : 0
        wt_deleted          : 0
        wt_type_changed     : 0
        wt_renamed          : 0
        ignored             : 0
        conflicts           : 0
        ahead               : 0
        behind              : 0
        stashes             : 0
        repo_name           : no_repository
        tag                 : no_tag
        branch              : no_branch
        remote              : ''
    }

    if ($raw_status | is-empty) { return $status }

    for s in $raw_status {
        let r = ($s | split row ' ')
        match $r.0 {
            '#' => {
                match ($r.1 | str substring 7..) {
                    'oid' => {
                        $status.commit_hash = ($r.2 | str substring 0..8)
                    }
                    'head' => {
                        $status.branch = $r.2
                    }
                    'upstream' => {
                        $status.remote = $r.2
                    }
                    'ab' => {
                        $status.ahead = ($r.2 | into int)
                        $status.behind = ($r.3 | into int | math abs)
                    }
                }
            }
            '1'|'2' => {
                match ($r.1 | str substring 0..1) {
                    'A' => {
                        $status.idx_added_staged += 1
                    }
                    'M' => {
                        $status.idx_modified_staged += 1
                    }
                    'R' => {
                        $status.idx_renamed += 1
                    }
                    'D' => {
                        $status.idx_deleted_staged += 1
                    }
                    'T' => {
                        $status.idx_type_changed += 1
                    }
                }
                match ($r.1 | str substring 1..2) {
                    'M' => {
                        $status.wt_modified += 1
                    }
                    'R' => {
                        $status.wt_renamed += 1
                    }
                    'D' => {
                        $status.wt_deleted += 1
                    }
                    'T' => {
                        $status.wt_type_changed += 1
                    }
                }
            }
            '?' => {
                $status.wt_untracked += 1
            }
            'u' => {
                $status.conflicts += 1
            }
        }
    }

    $status
}

export def _git_log_stat [n]  {
    do -i {
        git log -n $n --pretty=»¦«%h --stat
        | lines
        | reduce -f { c: '', r: [] } {|it, acc|
            if ($it | str starts-with '»¦«') {
                $acc | upsert c ($it | str substring 6.. )
            } else if ($it | find -r '[0-9]+ file.+change' | is-empty) {
                $acc
            } else {
                let x = (
                    $it
                    | split row ','
                    | each {|x| $x
                        | str trim
                        | parse -r "(?P<num>[0-9]+) (?P<col>.+)"
                        | get 0
                        }
                    | reduce -f {sha: $acc.c file:0 ins:0 del:0} {|i,a|
                        let col = if ($i.col | str starts-with 'file') {
                                'file'
                            } else {
                                $i.col | str substring ..3
                            }
                        let num = ($i.num | into int)
                        $a | upsert $col $num
                    }
                )
                $acc | upsert r ($acc.r | append $x)
            }
        }
        | get r
    }
}

export def _git_log [v num] {
    let stat = if $v {
        _git_log_stat $num
    } else { {} }
    let r = (do -i {
        git log -n $num --pretty=%h»¦«%s»¦«%aN»¦«%aE»¦«%aD
        | lines
        | split column "»¦«" sha message author email date
        | each {|x| ($x| upsert date ($x.date | into datetime))}
    })
    if $v {
        $r | merge $stat | reverse
    } else {
        $r | reverse
    }
}

def "nu-complete git log" [] {
    git log -n 32 --pretty=%h»¦«%s
    | lines
    | split column "»¦«" value description
    | each {|x| $x | update value $"($x.value)"}
}

def "nu-complete git branches" [] {
    git branch
    | lines
    | filter {|x| not ($x | str starts-with '*')}
    | each {|x| $"($x|str trim)"}
}

def remote_braches [] {
    git branch -r
    | lines
    | str trim
    | filter {|x| not ($x | str starts-with 'origin/HEAD') }
    | each {|x| $x | split row '/'}
}

def "nu-complete git remote branches" [context: string, offset: int] {
    let ctx = ($context | split row ' ')
    let rb = (remote_braches)
    if ($ctx | length) < 3 {
        $rb | each {|x| {value: $x.1, description: $x.0} }
    } else {
        $rb | filter {|x| $x.1 == $ctx.1 } | each {|x| $x.0}
    }
}

def "nu-complete git remotes" [] {
  ^git remote | lines | each { |line| $line | str trim }
}

def git_main_branch [] {
    git remote show origin
    | lines
    | str trim
    | find --regex 'HEAD .*?[：: ].+'
    | first
    | str replace 'HEAD .*?[：: ](.+)' '$1'
}

