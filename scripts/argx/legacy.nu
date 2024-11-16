def fold-command [] {
    let i = $in | split row -r '\s+'
    (($i | length) - 1)..0 | each {|t|
        $i | range ..$t | str join ' '
    }
}

def query-sign [] {
    let o = $in
    let cs = $o | fold-command
    let a = scope aliases
    let a = $a | filter {|x| $x.name in $cs }
    let cs = if ($a | is-empty) { $cs } else {
        $o | str replace $a.0.name $a.0.expansion | fold-command
    }
    let c = scope commands
    mut r = {}
    for x in $c {
        if $x.name in $cs {
            return ($x | insert expansion $cs.0)
        }
    }
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

export def parse-legacy [--plain(-p)] {
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
    let args = $args
    mut pos = $sign.positional
    | enumerate
    | reduce -f {} {|it, acc| $acc | insert $it.item ($args | get -i $it.index) }
    if ($sign.rest | is-not-empty) {
        $pos = $pos | insert $sign.rest.0 ($args | range ($sign.positional | length).. )
    }
    {
        args: $args
        pos: $pos
        opt: $opt
        cmd: $sign.cmd
    }
}

