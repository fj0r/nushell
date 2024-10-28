use completion.nu *
use core.nu *

export def todo-commit [
    tag: string@cmpl-tag-id
    --todo(-t): int@cmpl-todo-id
    --file(-f): string@cmpl-todo-md
    --amend(-a)
] {
    todo-done $todo
    todo-edit $todo
    todo-list -m $tag | save -f $file
    git add .
    mut a = []
    if $amend { $a ++= [ --amend ] }
    git commit ...$a -m $"(todo-title $todo) #($todo)"
}

export def todo-clean [] {
    todo-tag-clean ':trash'
}

export def todo-trash [] {
    todo-list ':trash' --all
}

export def tclean [] {
    let a = todo-list ':trash' --all
    print $a
    if ($a | is-empty) { return }
    let p = $'(ansi grey)------(char newline)Perform cleanup?(ansi reset)'
    let c = [yes no] | input list $p | str starts-with 'y'
    if $c {
        todo-tag-clean ':trash'
    }
}

export def todo-today [
    ...tags: any@cmpl-tag-id
    --all(-a)
    --md
    --md-list
    --raw
    --no-branch(-N)
    --work-in-process(-W)
    --finished(-F)
    --untagged(-U)
] {
    let d = (date now) - (date now | format date '%FT00:00:00' | into datetime)
    (todo-list
        ...$tags
        --updated $d --all=$all
        --md-list=$md_list --md=$md --raw=$raw
        --finished=$finished
        --work-in-process=$work_in_process
        --untagged=$untagged
        --no-branch=$no_branch
        )
}

export alias tc = todo-commit
export alias ta = todo-add
export alias tt = todo-attrs
export alias tl = todo-list
export alias td = todo-done
export alias te = todo-edit
export alias tm = todo-move
export alias tga = todo-tag-add
export alias tgc = todo-tag-clean
export alias tgr = todo-tag-rename
