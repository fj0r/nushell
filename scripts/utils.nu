export def 'filter index' [...idx] {
    reduce -f [] -n {|it, acc|
        if $it.index not-in ($idx|flatten) {
            $acc.item | append $it.item
        } else {
            $acc.item
        }
    }
}

export def "parse cmd" [] {
    $in
    | split row ' '
    | reduce -f { args: [], sw: '' } {|it, acc|
        if ($acc.sw|is-empty) {
            if ($it|str starts-with '-') {
                $acc | upsert sw $it
            } else {
                let args = ($acc.args | append $it)
                $acc | upsert args $args
            }
        } else {
            if ($it|str starts-with '-') {
                $acc
                | upsert $acc.sw true
                | upsert sw $it
            } else {
                $acc | upsert $acc.sw $it | upsert sw ''
            }
        }
    }
    | reject sw
}

export def index-need-update [index path] {
    let ts = do -i { ls $path | sort-by modified | reverse | get 0.modified }
    if ($ts | is-empty) { return false }
    let tc = do -i { ls $index | get 0.modified }
    if not (($index | path exists) and ($ts < $tc)) {
        mkdir (dirname $index)
        return true
    }
    return false
}

export def 'str max-length' [] {
    $in | reduce -f 0 {|x, a|
        if ($x|is-empty) { return $a }
        let l = ($x | str length)
        if $l > $a { $l } else { $a }
    }
}
