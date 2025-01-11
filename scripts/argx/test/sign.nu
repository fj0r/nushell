def test [
    --lll(-l): list<string>
    a b x? ...y --cd(-c) --ef(-e):string='asdf' --xyz(-x):string -g
    -h:int=123 --ij --lm
    ] {}

let x = scope commands | where name == test | first
let y = $x.signatures.any
| each {|y|
    let name = if ($y.parameter_name | is-empty) { $y.short_flag } else { $y.parameter_name }
    {
        name: $name
        type: $y.parameter_type
        shape: $y.syntax_shape
        optional: $y.is_optional
        default: $y.parameter_default
    }
}
| group-by type
| transpose k v
| reduce -f {} {|i,a| $a | insert $i.k $i.v }

print ($y | table -e)
