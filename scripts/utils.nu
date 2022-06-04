def filter-list [list, idx] {
    $list | reduce -f [] -n {|it, acc| if $it.index not-in $idx { $acc.item | append $it.item} else { $acc.item }}
}

def "parse cmd" [] {
    $in
    | split row ' '
    | reduce -f { args: [], sw: '' } {|it, acc|
        if ($acc.sw|empty?) {
            if ($it|str starts-with '-') {
                $acc | update sw $it
            } else {
                let args = ($acc.args | append $it)
                $acc | update args $args
            }
        } else {
            if ($it|str starts-with '-') {
                $acc
                | insert $acc.sw true
                | update sw $it
            } else {
                $acc | insert $acc.sw $it | update sw ''
            }
        }
    }
    | reject sw
}

