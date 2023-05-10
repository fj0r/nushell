export def 'filter index' [...idx] {
    reduce -f [] {|it, acc|
        if $it.index not-in ($idx|flatten) {
            $acc.item | append $it.item
        } else {
            $acc.item
        }
    }
}

export def "parse cmd" [] {
    let argv = ($in | split row ' ')
    mut pos = []
    mut opt = {}
    mut sw = ''
    for i in $argv {
        if ($i | str starts-with '-') {
            if not ($sw | is-empty) {
                $opt = ($opt | upsert $sw true)
            }
            $sw = $i
        } else {
            if ($sw | is-empty) {
                $pos ++= [$i]
            } else {
                $opt = ($opt | upsert $sw $i)
                $sw = ''
            }
        }
    }
    $opt.args = $pos
    $opt
}

export def "parse cmd1" [] {
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
