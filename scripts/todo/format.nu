export def 'todo format' [--md] {
    let i = $in
    $i | to tree | fmt tree --md=$md
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

def 'fmt tree' [level:int=0 --indent(-i):int = 4 --md] {
    for i in $in {
        let n = '' | fill -c ' ' -w ($level * $indent)
        $i | reject sub | fmt leaves $n --md=$md | each { print $in }
        if ($i.sub | is-not-empty) {
            $i.sub | fmt tree ($level + 1) --md=$md
        }
    }
}

def 'fmt leaves' [
    indent
    --md
] {
    let o = $in
    let done = if $o.done == 1 { '[x]' } else { '[ ]' }
    let title = $o.title
    let id = if ($md) {''} else {$o.id}
    [
        $"($indent)- ($done) (ansi default_bold)($title)(ansi reset)(ansi grey)($id)(ansi reset)"
    ]
}
