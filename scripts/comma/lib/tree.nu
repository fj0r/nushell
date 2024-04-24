export def node [] {
    let o = $in
    let _ = $env.comma_index
    let t = ($o | describe -d).type
    if $t == 'closure' {
        { end: true,  $_.act: $o }
    } else if ($_.act in $o) {
        { end: true,  ...$o }
    } else if ($_.sub in $o) {
        { end: false, ...$o }
    } else {
        { end: false, $_.sub: $o}
    }
}

def gather [cur _] {
    mut data = $in
    mut wth = ($data.watch? | default [])
    mut flt = ($data.filter? | default [])
    if $_.flt in $cur { $flt ++= ($cur | get $_.flt) }
    if $_.wth in $cur { $wth ++= ($cur | get $_.wth) }
    {
        filter: $flt
        watch: $wth
    }
}

export def select [data --strict] {
    let ph = $in
    let _ = $env.comma_index
    mut cur = $data | node
    mut ops = {} | gather $cur $_
    mut rest = []
    for i in $ph {
        if $cur.end {
            $rest ++= $i
        } else {
            $ops = ($ops | gather $cur $_)
            let sub = $cur | get $_.sub
            if $i in $sub {
                $cur = ($sub | get $i | node)
            } else {
                if $strict {
                    $cur = ({ do $_.tips "not found" $i } | node)
                } else {
                    $cur
                }
                break
            }
        }
    }
    {
        node: $cur
        rest: $rest
        ...$ops
    }
}

export def map [callback branch_handler?] {
    let t = $in | node
    let _ = $env.comma_index
    travel [] [] $t $callback $branch_handler $_
}

def travel [path g data callback branch_handler _] {
    if $data.end {
        do $callback $path $g $data $_
    } else {
        $data | get $_.sub
        | transpose k v
        | reduce -f [] {|x, a|
            let v = $x.v | node
            let g = if ($branch_handler | describe -d).type == 'closure' {
                $g | append (do $branch_handler $v $_)
            } else { $g }
            let r = travel ($path | append $x.k) $g $v $callback $branch_handler $_
            if ($r | is-empty) {
                $a
            } else {
                $a | append $r
            }
        }
    }
}


export def spread [list lv=0] {
    $list
    | each {|x|
        if ($x | describe -d).type == 'list' {
            spread $x ($lv + 1)
        } else {
            $x
        }
    } | flatten
}

