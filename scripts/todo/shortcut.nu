use completion.nu *
use data.nu *
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

export alias tc = todo-commit
export alias ta = todo-add
export alias tt = todo-attrs
export alias tl = todo-list
export alias td = todo-done
export alias te = todo-edit
export alias tclean = todo-clean
export alias tm = todo-move
export alias tca = todo-cat-add
export alias tcc = todo-cat-clean
export alias tcr = todo-cat-rename
export alias sa = scratch-add
export alias se = scratch-edit
export alias so = scratch-out
