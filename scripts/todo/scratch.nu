use common.nu *

export def 'todo scratch' [
    id?:int
    --nth(-n):int=0
    --type(-t):string='txt'
    --output(-o)
] {
    if $output {

    } else {
        if ($id | is-empty) {
            scratch-new --type $type
        } else {

        }
    }
}

export def scratch-new [--type(-t): string] {
    let now = date now | fmt-date
    let input = $"" | block-edit $"scratch-XXX.($type)" | lines
    let d = {
        title: ($input | first)
        type: $type
        content: ($input | range 1.. | str join (char newline))
        created: $now
        updated: $now
    }
    run $"insert into scratch \(($d | columns | str join ',')\)
        values \(($d | values | each {Q $in} | str join ',')\)
        returning id;"
}

export def scratch-edit [id --type(-t):string] {
    let old = run $"select title, type, content from scratch where id = ($id);"
    let type = if ($type | is-empty) { $old.type | first } else { $type }
    let input = [...$old.title ...$old.content]
    | str join (char newline)
    | block-edit $"scratch-XXX.($type)"
    | lines
    let d = {
        title: ($input | first)
        content: ($input | range 1.. | str join (char newline))
        type: $type
        updated: (date now | fmt-date)
    }
    | items {|k,v|
        $"($k) = (Q $v)"
    }
    | str join ','
    run $"update scratch set ($d);"
}

export def scratch-out [id] {
    run $"select content from scratch where id = ($id);" | get 0.content
}
