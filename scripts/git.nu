let DEFAULT_NUM = 32

def _git_stat_it [n]  {
    do -i {
        git log -n $n --pretty=»¦«%h --stat
        | lines
        | where {|x| ($x | str starts-with '»¦«') or (not ($x | find -r '[0-9]+ file.+change' | empty?))}
        | each {|it| if ($it | str starts-with '»¦«') { $it } else {
                $it
                | split row ','
                | each {|x| $x
                    | str trim
                    | parse -r "(?P<num>[0-9]+) (?P<col>.+)"
                    | get 0
                    }
                | reduce -f {} {|i,a|
                    let col = if ($i.col | str starts-with 'file') {
                            'file'
                        } else {
                            $i.col | str substring ',3'
                        }
                    let num = ($i.num | into int)
                    $a | upsert $col $num
                } }
        }
    }
}

def _git_stat [n]  {
    do -i {
        git log -n $n --pretty=»¦«%h --stat
        | lines
        | reduce -f { c: '', r: [] } {|it, acc|
            if ($it | str starts-with '»¦«') {
                $acc | upsert c ($it | str substring '6,')
            } else if ($it | find -r '[0-9]+ file.+change' | empty?) {
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
                                $i.col | str substring ',3'
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

def _git_log [v num] {
    let stat = if $v {
        _git_stat $num
    } else { {} }
    let r = do -i {
        git log -n $num --pretty=%h»¦«%s»¦«%aN»¦«%aE»¦«%aD
        | lines
        | split column "»¦«" sha message author email date
        | each {|x| ($x| upsert date ($x.date | into datetime))}
    }
    if $v {
        $r | merge { $stat }
    } else {
        $r
    }
}

def "nu-complete git log" [] {
    git log -n $DEFAULT_NUM --pretty=%h»¦«%s
    | lines
    | split column "»¦«" value description
}

def glg [
    commit?: string@"nu-complete git log"
    --verbose(-v):bool
    --num(-n):int=$DEFAULT_NUM
] {
    if ($commit|empty?) {
        _git_log $verbose $num
    } else {
        git log --stat -p -n 1 $commit
    }
}

def gpp! [] {
    git add --all
    git commit -v -a --no-edit --amend
    git push --force
}

def gha [] {
    git log --pretty=%h»¦«%aN»¦«%s»¦«%aD
    | lines
    | split column "»¦«" sha1 committer desc merged_at
    | histogram committer merger
    | sort-by merger
    | reverse
}

def "nu-complete git branches" [] {
  ^git branch | lines | each { |line| $line | str replace '[\*\+] ' '' | str trim }
}

def "nu-complete git remotes" [] {
  ^git remote | lines | each { |line| $line | str trim }
}

def gm [branch:string@"nu-complete git branches"] {
    git merge $branch
}

extern "git reset" [
    sha?:string@"nu-complete git log"
    --hard:bool
]

alias gp = git push
alias gl = git pull
alias ga = git add
alias gaa = git add --all
alias gapa = git add --patch
alias gau = git add --update
alias gav = git add --verbose
alias gap = git apply
alias gapt = git apply --3way

alias gb = git branch
alias gba = git branch -a
alias gbd = git branch -d
alias gbda = 'git branch --no-color --merged | command grep -vE "^(\+|\*|\s*($(git_main_branch)|development|develop|devel|dev)\s*$)" | command xargs -n 1 git branch -d'
alias gbD = git branch -D
alias gbl = git blame -b -w
alias gbnm = git branch --no-merged
alias gbr = git branch --remote
alias gbs = git bisect
alias gbsb = git bisect bad
alias gbsg = git bisect good
alias gbsr = git bisect reset
alias gbss = git bisect start

alias gc = git commit -v
alias gc! = git commit -v --amend
alias gcn! = git commit -v --no-edit --amend
alias gca = git commit -v -a
alias gca! = git commit -v -a --amend
alias gcan! = git commit -v -a --no-edit --amend
alias gcans! = git commit -v -a -s --no-edit --amend
alias gcam = git commit -a -m
alias gcsm = git commit -s -m
alias gcb = git checkout -b
alias gcf = git config --list
alias gcl = git clone --recurse-submodules
alias gclean = git clean -id
alias gpristine = git reset --hard && git clean -dffx
alias gcm = git checkout $(git_main_branch)
alias gcd = git checkout develop
alias gcmsg = git commit -m
alias gco = git checkout
alias gcount = git shortlog -sn
alias gcp = git cherry-pick
alias gcpa = git cherry-pick --abort
alias gcpc = git cherry-pick --continue
alias gcs = git commit -S

alias gd = git diff
alias gdca = git diff --cached
alias gdcw = git diff --cached --word-diff
alias gdct = git describe --tags $(git rev-list --tags --max-count=1)
alias gds = git diff --staged
alias gdt = git diff-tree --no-commit-id --name-only -r
alias gdw = git diff --word-diff

alias gr = git remote
alias gra = git remote add
alias grb = git rebase
alias grba = git rebase --abort
alias grbc = git rebase --continue
alias grbd = git rebase develop
alias grbi = git rebase -i
alias grbm = git rebase $(git_main_branch)
alias grbo = git rebase --onto
alias grbs = git rebase --skip
alias grev = git revert
alias grh = git reset
alias grhh = git reset --hard
alias groh = git reset origin/$(git_current_branch) --hard
alias grm = git rm
alias grmc = git rm --cached
alias grmv = git remote rename
alias grrm = git remote remove
alias grs = git restore
alias grset = git remote set-url
alias grss = git restore --source
alias grst = git restore --staged
alias grt = cd "$(git rev-parse --show-toplevel || echo .)"
alias gru = git reset --
alias grup = git remote update
alias grv = git remote -v

alias gsb = git status -sb
alias gsd = git svn dcommit
alias gsh = git show
alias gsi = git submodule init
alias gsps = git show --pretty=short --show-signature
alias gsr = git svn rebase
alias gss = git status -s
alias gs = git status


alias gstaa = git stash apply
alias gstc = git stash clear
alias gstd = git stash drop
alias gstl = git stash list
alias gstp = git stash pop
alias gsts = git stash show --text
alias gstu = gsta --include-untracked
alias gstall = git stash --all
alias gsu = git submodule update
alias gsw = git switch
alias gswc = git switch -c

alias gts = git tag -s

alias gunignore = git update-index --no-assume-unchanged
alias gup = git pull --rebase
alias gupv = git pull --rebase -v
alias gupa = git pull --rebase --autostash
alias gupav = git pull --rebase --autostash -v
alias glum = git pull upstream $(git_main_branch)

# cat ($nu.config-path | path dirname | path join 'scripts' | path join 'a.nu' )
