export def 'todo format' [] {
    let i = $in
    $i | to tree
}

def 'to tree' [] {
    let o = $in
    mut x = $o | reduce -f {} {|i,a|
        let n = $i | select parent_id | insert sub []
        $a | insert ($i.id | into string) $n
    }
    return $x
    for i in ($x | transpose k v) {
        if ($i.v.parent_id != -1) {
            let p = [$i.v.parent_id sub]|into cell-path
            $x | upsert $p ($x | get $p | append $i.k)
        }
    }

}

def 'fmt branches' [] {

}

def 'fmt leaves' [--indent(-i)] {

}
