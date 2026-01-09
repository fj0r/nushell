def default_parameter [i] {
    if ($i.parameter_default | is-empty) {
        return ''
    }
    match $i.syntax_shap {
        string => $' = "(i.parameter_default)"'
        _ => $' = (i.parameter_default)'
    }
}

export def alias-to-fn [alias prelude?: list = []] {
    let cmd = scope aliases | where name == $alias | first | get expansion
    wrap-fn $cmd $alias $prelude
}

export def wrap-fn [alias cmd prelude?: list = [] ] {
    use argx
    let c = $cmd | argx parse
    let s = scope commands | where name == $c.tag | first | get signatures
    mut args = []
    mut uses = []
    for i in $s.any {
        match $i.parameter_type {
            positional => {
                let q = if $i.is_optional { '?' } else { '' }
                let d = default_parameter $i
                let v = $c.pos | get -o $i.parameter_name
                if ($v | is-empty) {
                    $args ++= [$"($i.parameter_name)($q): ($i.syntax_shape)($d)"]
                    $uses ++= [$"$($i.parameter_name)"]
                } else {
                    $uses ++= [$v]
                }
            }
            named => {
                let d = default_parameter $i
                let v = $c.opt | get -o $i.parameter_name
                if ($v | is-empty) {
                    $args ++= [$"--($i.parameter_name)\(-($i.short_flag)\): ($i.syntax_shape)($d)"]
                    $uses ++= [$"--($i.parameter_name) $($i.parameter_name)"]
                } else {
                    $uses ++= [$"--($i.parameter_name) ($v)"]
                }
            }
            switch => {
                let v = $c.opt | get -o $i.parameter_name
                if ($v | is-empty) {
                    $args ++= [$"--($i.parameter_name)\(-($i.short_flag)\)"]
                    $uses ++= [$"--($i.parameter_name)=$($i.parameter_name)"]
                } else {
                    $uses ++= [$"--($i.parameter_name)"]
                }
            }
            rest => {
                let v = $c.pos | get -o $i.parameter_name
                $args ++= [$"...($i.parameter_name): ($i.syntax_shape)"]
                $uses ++= [$"($v | str join ' ') ...$($i.parameter_name)"]
            }
        }
    }
    $'
    export def ($alias) [($args | str join ", ")] {
        ($prelude | str join (char newline))
        ([$c.tag ...$uses] | str join " ")
    }
    ' | str trim | str replace -rma $'^\s{4}' ''
}
