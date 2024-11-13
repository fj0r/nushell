use completion.nu *
use tag_base.nu *

export def snew [
    ...xtags:string@cmpl-tag-3
    --parent(-f):int
    --scratch(-t): int@cmpl-scratch-id
] {
    if ($scratch | is-not-empty) { scratch-out } else { $in | scratch-in }
    | ai-do trans-to en -o
    | scratch-add ...$xtags -f $parent
}


export def cmpl-todo-md [] {
    ls **/TODO.md | get name
}

export def scommit [
    ...xtags:string@cmpl-tag-3
    --scratch(-t): int@cmpl-scratch-id
    --file(-f): string@cmpl-todo-md
    --amend(-a)
] {
    scratch-done $scratch
    scratch-edit $scratch
    scratch-list -m ...$xtags | save -f $file
    git add .
    mut a = []
    if $amend { $a ++= [ --amend ] }
    git commit ...$a -m $"(scratch-title $scratch) #($scratch)"
}
