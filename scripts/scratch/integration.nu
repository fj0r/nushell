export def tn [--parent(-p):int --scratch(-s)] {
    if $scratch { scratch-out } else { $in | scratch-add }
    | ai-do trans-to en -o
    | scratch-add -p $parent --edit
}
