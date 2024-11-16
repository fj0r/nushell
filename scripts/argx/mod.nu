def get-sign [] {
    let expr = $in
    let o = scope commands | where decl_id == $expr.decl_id | first
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
        switch: $s
        named: $n
        positional: ($p ++ $pr)
        rest: $r
    }
}

export def get-ast [] {
    let d = ast $in -j -m | get block | from json
    let cur = $d | get -i pipelines | last | get elements | last
    $cur.expr.expr.Call
}

def expr-to-value [expr] {
    if ($expr | describe -d).type == record {
        $expr
        | items {|k, v|
            match $k {
                List => {
                    $v | each { expr-to-value $in.Item.expr }
                }
                FullCellPath => {
                    $v.head.expr.Record | reduce -f {} {|i,a|
                        let p = $i.Pair | get expr
                        $a | insert (expr-to-value $p.0) (expr-to-value $p.1)
                    }
                }
                Closure => {
                    # TODO:
                    null
                }
                String | Int | Bool => { $v }
                _ => { $"($k):($v)" }
            }
        }
        | first
    } else {
        null
    }
}

def get-args [] {
    let o = $in
    let a = $o.arguments
    let s = $o.head.start
    mut r = {
        args: []
        opt: {}
    }
    for i in $a {
        if ('Named' in $i) {
            mut name = ''
            mut expr = {Bool: true}
            for j in $i.Named {
                if ($j | is-not-empty) {
                    if ($j.item? | is-not-empty) {
                        $name = $j.item
                    }
                    if ($j.expr? | is-not-empty) {
                        $expr = $j.expr
                    }
                }
            }
            $r.opt = $r.opt | upsert $name (expr-to-value $expr)
        }
        if ('Positional' in $i) {
            $r.args ++= [(expr-to-value $i.Positional.expr)]
        }
    }

    $r
}

export def parse [
    --pos(-p)
] {
    let cmd = $in
    let ast = $cmd | get-ast
    let x = $ast | get-args
    if not $pos {
        return $x
    }
    let sign = $ast | get-sign

    mut pos = $sign.positional
    | enumerate
    | reduce -f {} {|it, acc| $acc | insert $it.item ($x.args | get -i $it.index) }
    if ($sign.rest | is-not-empty) {
        $pos = $pos | insert $sign.rest.0 ($x.args | range ($sign.positional | length).. )
    }
    $x | insert pos $pos
}
