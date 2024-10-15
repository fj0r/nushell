def query-sign [] {
    let i = $in
    let a = scope aliases
    | filter {|x| $i | str starts-with $x.name}
    | sort-by name -r
    let e = if ($a | is-empty) { $i } else { $i | str replace $a.0.name $a.0.expansion }
    scope commands
    | filter {|x| $e | str starts-with $x.name}
    | sort-by name -r
    | first
    | insert expansion $e
}

def get-sign [] {
    let o = $in
    let cmd = $o | get name
    let x = $o | get -i signatures?.any?
    mut s = []
    mut n = {}
    mut p = []
    mut pr = []
    mut r = []
    for it in $x {
        if $it.parameter_type == 'switch' {
            if ($it.short_flag | is-not-empty) {
                $s ++= $it.short_flag
            }
            if ($it.parameter_name | is-not-empty) {
                $s ++= $it.parameter_name
            }
        } else if $it.parameter_type == 'named' {
            if ($it.parameter_name | is-empty) {
                $n = ($n | upsert $it.short_flag $it.short_flag)
            } else if ($it.short_flag | is-empty) {
                $n = ($n | upsert $it.parameter_name $it.parameter_name)
            } else {
                $n = ($n | upsert $it.short_flag $it.parameter_name)
            }
        } else if $it.parameter_type == 'positional' {
            if $it.is_optional == false {
                $p ++= $it.parameter_name
            } else {
                $pr ++= $it.parameter_name
            }
        } else if $it.parameter_type == 'rest' {
            $r ++= $it.parameter_name
        }
    }
    {
        expansion: $o.expansion
        cmd: $cmd
        switch: $s
        named: $n
        positional: ($p ++ $pr)
        rest: $r
    }
}

# "test -h [123 (3213 3)] 123 `a sdf` --cd --ef sadf -g" | argx token 'test'
def token [cmd] {
    let s = $in
    | str substring ($cmd | str length)..
    | str trim
    | split row ''
    mut par = []
    mut res = []
    mut cur = ''
    mut esc = false
    for c in $s {
        if $c == '\' {
            $esc = true
        } else {
            if $esc {
                $cur ++= $c
                $esc = false
            } else {
                if $c == ' ' and ($par | length) == 0 {
                    $res ++= [$cur]
                    $cur = ''
                } else {
                    if $c in ['{' '[' '('] {
                        $par ++= $c
                    }
                    if $c in ['}' ']' ')'] {
                        $par = ($par | range ..-2)
                    }
                    if $c in ['"' "'" '`'] {
                        if ($par | length) > 0 and ($par | last) == $c {
                            $par = ($par | range ..-2)
                        } else {
                            $par ++= $c
                        }
                    }
                    $cur ++= $c
                }

            }
        }
    }
    $res ++= $cur
    return $res
}

export def parse [--plain(-p)] {
    let cmd = $in
    let sign = $cmd | query-sign | get-sign
    let token = $sign.expansion | token $sign.cmd
    mut sw = ''
    mut args = []
    mut opt = {}
    for c in $token {
        if ($sw | is-empty) {
            if ($c | str starts-with '-') {
                let c = if ($c | str substring 1..<2) != '-' {
                    let k = ($c | str substring 1..)
                    if $k in $sign.named {
                        $'($sign.named | get $k)'
                    } else {
                        $k
                    }
                } else {
                    $c | str substring 2..
                }
                if $c in $sign.switch {
                    $opt = ($opt | upsert $c true)
                } else {
                    $sw = $c
                }
            } else {
                $args ++= [$c]
            }
        } else {
            $opt = ($opt | upsert $sw $c)
            $sw = ''
        }
    }
    let pos = $args| range 0..<($sign.positional | length)
    | enumerate
    | reduce -f {} {|it, acc|
        $acc | upsert ($sign.positional | get $it.index) $it.item
    }
    let rest = $args | range ($sign.positional | length)..-1 | default []
    {
        args: $args
        pos: $pos
        rest: $rest
        opt: $opt
        cmd: $sign.cmd
    }
}
