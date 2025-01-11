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

export def parse [
    --pos(-p)
] {
    let cmd = $in

    let ast = $cmd | get-ast
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

    mut pos = $sign.positional?
    | get name
    | enumerate
    | reduce -f {} {|it, acc| $acc | insert $it.item ($x.args | get -i $it.index) }

    if ($sign.rest? | is-not-empty) {
        $pos = $pos | insert $sign.rest.0.name (
            $x.args | range ($sign.positional | length)..
        )
    }

    $x | insert pos $pos
}

export-env {
    $env.NU_ARGX_EXISTS = true
}

export def test [$s -p] {
    print $"(ansi yellow)($s)(ansi reset)"
    let r = $s | parse --pos=$p | to yaml
    print $"(ansi grey)($r)(ansi reset)"
}
