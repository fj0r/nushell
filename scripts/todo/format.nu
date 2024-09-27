export def 'todo format' [] {
    let i = $in
    $i | to tree | fmt tree
}

def 'to tree' [] {
    let o = $in | each { $in | insert sub [] }
    mut x = $o | reduce -f {} {|i,a|
        $a | insert ($i.id | into string) $i
    }
    for i in $o {
        if ($i.parent_id != -1) {
            let p = [($i.parent_id | into string) sub] | into cell-path
            $x = $x | upsert $p ($x | get $p | append $i)
        }
    }
    $x
    | items {|k,v| if $v.parent_id == -1 { $v } }
    | filter {$in | is-not-empty}
}

def 'fmt tree' [level:int=0 --indent(-i):int = 4] {
    for i in $in {
        let n = '' | fill -c ' ' -w ($level * $indent)
        $i | reject sub | fmt leaves $n | print $in
        if ($i.sub | is-not-empty) {
            $i.sub | fmt tree ($level + 1)
        }
    }
}

def 'fmt leaves' [indent] {
    $in | to yaml | lines | each { $"($indent)($in)"} | str join (char newline)
}
