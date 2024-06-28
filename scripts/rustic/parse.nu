def lit [e, -t: string] {
    {|pos|
        let o = $in
        let l = $e | str length
        let a = ($o | str substring 0..<$l)
        if $a == $e {
            {
                val: $e
                len: $l
            }
        } else {
            {
                err: [$e $a]
                len: -1
            }
        } | merge {
            type: lit
            tag: $t
            pos: $pos
        }
    }
}

def spy [l=30] {
    {|pos|
        let o = $in
        {
            len: 0
            val: ($o | str substring ..$l)
            pos: $pos
        }
    }
}

def line [t: string] {
    {|pos|
        let o = $in
        let i = $o | str index-of "\n"
        if $i < 0 {
            {
                len: -1
            }
        } else {
            {
                val: ($o | str substring 0..<($i))
                len: $i
            }
        } | merge {
            typ: line
            tag: $t
            pos: $pos
        }
    }
}

def empty [t='', --with-line(-l)] {
    let re = if $with_line { '^(?<s>[ \s\n]+)' } else { '^(?<s>[ \s]+)' }
    {|pos|
        let o = $in
        let i = $o | parse -r $re
        if ($i | is-empty) {
            {
                len: -1
            }
        } else {
            {
                len: ($i | get 0.s | str length)
            }
        } | merge {
            typ: empty
            pos: $pos
        }
    }
}

def one-or-more [] {

}

def one-of [] {

}


export def one-by-one [t: string, s] {
    {|pos=0|
        let o = $in
        mut p = 0
        mut r = []
        for i in $s {
            let y = $o | str substring $p..
            let x = $y | do $i $p
            if $x.len < 0 {
                return {
                    typ: seq
                    tag: $t
                    ctx: $r
                    err: $x
                    len: -1
                    pos: $pos
                }
            } else {
                $p += $x.len
            }
            $r ++= $x
        }
        {
            typ: seq
            tag: $t
            val: $r
            len: ($p + ($r | last).len)
            pos: $pos
        }
    }
}


rustic --help | complete | get stdout
| do (one-by-one main [
    (line header)
    (empty 'x' -l)
    (one-by-one 'usage' [
        (lit Usage:)
        (spy)
    ])
])
| get val
