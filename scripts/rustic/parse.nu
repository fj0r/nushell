def spy [l=9] {
    if true {
        $in | str substring ..$l
    }
}

def word [t: string] {
    {|pos|
        let o = $in
        let i = $o | parse -r '^(?<s>[^\s]+)'
        if ($i | is-empty) {
            {
                len: -1
                pos: $pos
            }
        } else {
            {
                len: ($i.0.s | str length)
                pos: $pos
                val: $i.0.s
            }
        } | merge {
            typ: word
            tag: $t
            ctx: ($o | spy)
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
                len: $l
                pos: $pos
                val: $e
            }
        } else {
            {
                len: -1
                pos: $pos
                err: $e
            }
        } | merge {
            typ: lit
            tag: $t
            ctx: ($o | spy)
        }
    }
}

def cap0 [t: string, e] {
    {|pos|
        let o = $in
        let r = $o | parse -r $"^($e).*"
        if ($r | is-empty) {
            {
                len: -1
                pos: $pos
                err: $e
            }
        } else {
            let r = $r.0.capture0
            {
                len: ($r | str length)
                pos: $pos
                val: $r
            }
        } | merge {
            typ: cap
            tag: $t
            ctx: ($o | spy)
        }
    }

}

def end-of-line [t: string] {
    {|pos|
        let o = $in
        let i = $o | str index-of (char newline)
        if $i < 0 {
            {
                len: -1
                pos: $pos
            }
        } else {
            {
                len: ($i + 1) # include "\n"
                pos: $pos
                val: (if $i == 0 { '' } else { $o | str substring 0..<($i) })
            }
        } | merge {
            typ: eol
            tag: $t
            ctx: ($o | spy)
        }
    }
}

def new-line [t=''] {
    {|pos|
        let o = $in
        let i = $o | str substring ..<1
        if $i == (char newline) {
            {
                len: 1
                pos: $pos
                val: ''
            }
        } else {
            {
                len: -1
                pos: $pos
            }
        } | merge {
            typ: nl
            tag: $t
            ctx: ($o | spy)
        }
    }
}


def space [t='', --with-line(-l)] {
    let re = if $with_line { '^(?<s>[ \s\n]+)' } else { '^(?<s>[ \s]+)' }
    {|pos|
        let o = $in
        let i = $o | parse -r $re
        if ($i | is-empty) {
            {
                len: -1
                pos: $pos
            }
        } else {
            let v = $i.0.s
            if (not $with_line) and ($v | str index-of (char newline)) >= 0 {
                {
                    len: -1
                    pos: $pos
                }
            } else {
                {
                    len: ($v | str length)
                    pos: $pos
                    val: ''
                }
            }
        } | merge {
            typ: space
            tag: $t
            ctx: ($o | spy)
        }
    }
}

def one-of [t: string, s] {
    {|pos|
        let o = $in
        mut err = {}
        for i in $s {
            let x = $o | do $i $pos
            if $x.len < 0 {
                $err = $x
                continue
            } else {
                return ($x | merge {typ: $"select:($x.typ)"})
            }
        }
        {
            typ: select
            tag: $t
            len: -1
            pos: $pos
            ctx: ($o | spy)
            err: $err
        }
    }

}

def _more [t: string, s, --zero(-z), --one(-o)] {
    {|pos|
        let o = $in
        mut p = 0
        mut r = []
        mut err = {}
        while true {
            if $one and ($r | length) > 0 {
                break
            }
            let y = $o | str substring $p..
            let x = $y | do $s $p
            if $x.len < 0 {
                $err = $x
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
                err: $err
            }
        } else {
            {
                len: ($p + ($r | last).len)
                pos: $pos
                val: $r
            }
        } | merge {
            typ: repeat
            tag: $t
            ctx: ($o | str substring $p.. | spy)
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
                    len: -1
                    pos: $pos
                    ctx: ($o | spy)
                    result: $r
                    err: $x
                }
            } else {
                $p += $x.len
            }
            $r ++= $x
        }
        {
            typ: seq
            tag: $t
            len: $p
            pos: $pos
            val: $r
            ctx: ($o | spy)
        }
    }
}

#let a = rustic --help | complete | get stdout

let b = 'rustic - fast, encrypted, deduplicated backups powered by Rust

Usage: rustic [OPTIONS] <COMMAND>

   
Commands:
  backup       Backup to  
  cat          Show raw


Commands:
  1backup       Backup to
  1cat          Show raw

Commands:
  2backup       Backup to
  2cat          Show raw

'

$b | do (one-by-one main [
    (end-of-line header)
    (space 'x' -l)
    (one-or-more 'body'
        (one-of 'section' [
            (one-by-one 'usage' [
                (cap0 'usage' '(Usage):')
                (lit '' ':')
                (space '')
                (end-of-line 'usage')
            ])
            (one-by-one 'commands' [
                (space '' -l)
                (cap0 'h' '(Commands):')
                (lit '' ':')
                (new-line)
                (one-or-more 'cmd'
                    (one-by-one 'cmd' [
                        (space '')
                        (word '')
                        (space '')
                        (end-of-line 'desc')
                    ])
                )
            ])
            (one-by-one 'option' [
                (space '' -l)
                (cap0 'option' '(.+):')
                (lit '' ':')
            ])
        ])
    )
])
| get val.2.val
| table -e
