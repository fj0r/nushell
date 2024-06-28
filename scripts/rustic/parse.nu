def _tmp [t: string, e] {
    {|pos|
        let o = $in
        if ($o | is-empty) {
            {
            }
        } else {
            {
            }
        } | merge {
            type: tmp
            tag: $t
            pos: $pos
        }
    }
}

def lit [t: string, e] {
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
            type: id
            tag: $t
            pos: $pos
        }
    }
}

def cap0 [t: string, e] {
    {|pos|
        let o = $in
        let r = $o | parse -r $"^($e).*"
        if ($r | is-empty) {
            {
                ctx: ($o | str substring ..30)
                err: $e
                len: -1
            }
        } else {
            let r = $r.0.capture0
            {
                val: $r
                len: ($r | str length)
            }
        } | merge {
            type: id
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

def end-of-line [t: string] {
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

def empty [t='', --with-line(-l), --hide(-h)] {
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
                len: ($i.0.s | str length)
            }
        } | merge {
            typ: empty
            pos: $pos
            hide: $hide
        }
    }
}

def one-of [t: string, s] {
    {|pos|
        let o = $in
        for i in $s {
            let x = $o | do $i $pos
            if $x.len < 0 {
                continue
            } else {
                return $x
            }
        }
        {
            type: choice
            tag: $t
            len: -1
            pos: $pos
        }
    }

}

def _more [t: string, s, --zero(-z), --one(-o)] {
    {|pos|
        let o = $in
        mut p = 0
        mut r = []
        while true {
            if $one and ($r | length) > 0 {
                break
            }
            let y = $o | str substring $p..
            let x = $y | do $s $p
            if $x.len < 0 {
                break
            } else {
                $p += $x.len
            }
            $r ++= $x
        }
        if (not $zero) and ($r | is-empty)  {
            {
                len: -1
                pos: $pos
            }
        } else {
            {
                val: $r
                len: ($p + ($r | last).len)
                pos: $pos
            }
        } | merge {
            typ: repeat
            tag: $t
        }
    }
}

def one-or-more [t: string, s] {
    $in | _more $t $s
}

def zero-or-more [t: string, s] {
    $in | _more $t $s --zero
}

def zero-or-one  [t: string, s] {
    $in | _more $t $s --one
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
            # TODO: hide
            if not ($x.hide? | default false) {
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
    (end-of-line header)
    (empty 'x' -l -h)
    (one-or-more 'body'
        (one-of 'section' [
            (one-by-one 'usage' [
                (cap0 'usage' '(Usage):')
                (lit '' ':')
                (end-of-line 'usage')
                (empty '' -l -h)
            ])
            (one-by-one 'commands' [
                (cap0 'cmds' '(Commands):')
                (lit '' ':')
                (empty '' -l -h)
                (one-or-more 'cmd'
                    (one-by-one 'cmd' [
                        

                    ])
                )
            ])
            (one-by-one 'option' [
                (cap0 'option' '(.+):')
                (lit '' ':')
            ])
        ])
    )
])
| table -e
