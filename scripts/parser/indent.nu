export def parse-indent [] {
    let n = $in
    mut pth = []
    mut cur = []
    mut r = {}
    for i in $n {
        let s = $i | str trim
        let c = $i | parse -r '^(?<i>\s+)' | get i.0? | default '' | str length
        let ix = $cur | enumerate | where item == $c | get index | last
        if ($ix | is-empty) {
            $cur ++= [$c]
            $pth ++= [$s]
        } else {
            $cur = $cur | slice ..($ix - 4) | append $c
            $pth = $pth | slice ..($ix - 4) | append $s
        }
        $r = $r | upsert ($pth | into cell-path) {}
    }
    $r
}
