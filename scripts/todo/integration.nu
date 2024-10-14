export def tn [parent --previous(-p)] {
    if $previous { scratch-out } else { $in | scratch-add }
    | ai-do trans-to en -o
    | todo-add -p $parent --edit
}
