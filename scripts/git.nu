def _git_log [] {
    git log --pretty=%h»¦«%s»¦«%aN»¦«%aE»¦«%aD
    | lines
    | split column "»¦«" sha message author email date
    | each {|x| ($x| update date ($x.date | into datetime))}
}

def "nu-complete git log" [] {
    _git_log
    | each {|x| {description: $x.message value: $x.sha extra: [a b c]}}
}

def glg [commit?: string@"nu-complete git log", -n: int=20] {
    if ($commit|empty?) {
        _git_log | take $n
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
