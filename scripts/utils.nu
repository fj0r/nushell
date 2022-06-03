def filter-list [list, idx] {
    $list | reduce -f [] -n {|it, acc| if $it.index not-in $idx { $acc.item | append $it.item} else { $acc.item }}
}
