use completion.nu *
use core.nu *
use scratch.nu *

export def todo-commit [
    tag: string@cmpl-category
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
    todo-cat-clean ':trash'
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
        todo-cat-clean ':trash'
    }
}

export def todo-today [
    ...tags: any@cmpl-category
    --all(-a)
    --important(-i): int@cmpl-level
    --urgent(-u): int@cmpl-level
    --challenge(-c): int@cmpl-level
    --finished
    --md
    --md-list
    --raw
    --work-in-process(-W)
    --finished(-F)
    --untagged(-U)
] {
    let d = (date now) - (date now | format date '%FT00:00:00' | into datetime)
    (todo-list --updated $d --created $d --work-in-process=$work_in_process --finished=$finished
     --all=$all --important=$important --urgent=$urgent --challenge=$challenge
     --md-list=$md_list --md=$md --raw=$raw
     --untagged=$untagged
     ...$tags)
}

export alias tc = todo-commit
export alias ta = todo-add
export alias tt = todo-attrs
export alias tl = todo-list
export alias td = todo-done
export alias te = todo-edit
export alias tm = todo-move
export alias tca = todo-cat-add
export alias tcc = todo-cat-clean
export alias tcr = todo-cat-rename
export alias sa = scratch-add
export alias se = scratch-edit
export alias so = scratch-out
