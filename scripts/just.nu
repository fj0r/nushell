def cmpl-just-recipes [] {
    ^just --unsorted --dump --dump-format json
        | from json
        | get recipes
        | transpose k v
        | each {|x|
            {
                value: $x.k,
                description: (
                    $x.v.parameters
                    | each {|y|
                        if ($y.default|is-empty) {
                            $y.name
                        } else {
                            $'($y.name)="($y.default)"'
                        }
                    }
                    | str join ' '
                )
            }
        }
}

def cmpl-just-args [context: string, offset: int] {
    let r = ($context | split row ' ')
    ^just -u --dump --dump-format json
        | from json
        | get recipes
        | get ($r.1)
        | get body
        | each {|x| {description: ($x | get 0) }}
        | prepend ''

}

export def main [
    recipes?: string@cmpl-just-recipes
    ...args: any@cmpl-just-args
] {
    if ($recipes | is-empty) {
        ^just
    } else {
        ^just $recipes ...$args
    }
}