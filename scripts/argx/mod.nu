export def get-ast [offset?: int] {
    let d = ast $in -j -m | get block | from json
    let cur = if ($offset | is-empty) {
        $d
        | get -i pipelines | last
        | get elements | last
    } else {
        let p = $d | get -i pipelines
        let o = $d.span.start + $offset
        mut r = null
        for i in $p {
            for j in $i.elements {
                let s = $j.expr.span
                if ($s.start <= $o) and ($o <= $s.end) {
                    $r = $j
                    break
                }
            }
        }
        $r
    }
    if ($cur | is-not-empty) {
        $cur.expr.expr.Call
    } else {
        null
    }
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
                Filepath => { $v.0 }
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

export def parse [offset?: int] {
    let cmd = $in

    let ast = $cmd | get-ast $offset
    if ($ast | is-empty) { return }
    let x = $ast | get-args

    let sign = scope commands
    | where decl_id == $ast.decl_id | first
    | get -i signatures?.any?
    | insert name {|y|
        if ($y.parameter_name | is-empty) {
            $y.short_flag
        } else {
            $y.parameter_name
        }
    }

    let defaults = $sign
    | reduce -f {} {|i,a|
        if ($i.parameter_default | is-not-empty) {
            $a | insert $i.name $i.parameter_default
        } else {
            $a
        }
    }

    let sign = $sign | group-by parameter_type

    let opt = $sign.named? | default []
    | get -i name
    | reduce -f $x.opt {|i, a|
        if ($i in $defaults) and ($i not-in $a) {
            $a | insert $i ($defaults | get $i)
        } else {
            $a
        }
    }

    mut pos = $sign.positional? | default []
    | get name
    | enumerate
    | reduce -f {} {|it, acc|
        let v = $x.args | get -i $it.index
        let v = if ($v | is-empty) { $defaults | get -i $it.item } else { $v }
        $acc | insert $it.item $v
    }

    if ($sign.rest? | is-not-empty) {
        # HACK: If the name of the rest parameter is `rest`, then the name is empty.
        let name = $sign.rest.0.name | default 'rest'
        $pos = $pos | insert $name ($x.args | slice ($sign.positional? | length)..)
    }

    $x
    | insert pos $pos
    | update opt $opt
}

export-env {
    $env.NU_ARGX_EXISTS = true
}

export def test [$s -p] {
    print $"(ansi yellow)($s)(ansi reset)"
    let r = $s | parse | to yaml
    print $"(ansi grey)($r)(ansi reset)"
}
