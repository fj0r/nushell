use parser *

def ts [$t] {
    {|pos|
        let o = $in
        let i = $o | parse -r '^(?<s>.+?)({{|}})'
        if ($i | is-not-empty) {
            {
                len: ($i.0.s | str length)
                pos: $pos
                val: ($i.0.s)
            }
        } else {
            {
                len: ($o | str length)
                val: $o
                pos: $pos
            }
        } | merge {
            typ: mid
            tag: $t
        }
    }
}

let a = 'a {{ b {{ c}} d e}} f'
let b = 'a {{ b}}c'
let c = 'a {{ b {{ c {{a{{jj}}x}}y}} d e}} f'

def x [] {
    {||
        $in | do (one-by-one '' [
            (ts '')
            (lit '{' '{{')
                (one-of 'sub' [
                    (x)
                    (ts '')
                ])
            (lit '}' '}}')
            (ts '')
        ])
    }
}


$c | do (x)
| table -e
