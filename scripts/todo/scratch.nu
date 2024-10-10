use common.nu *

def cmpl-scratch-id [] {
    run $"select id as value, title || ' <' || type || '>' as description
        from scratch order by updated desc limit 10;"
}

export def scratch-add [--type(-t): string='md'] {
    let now = date now | fmt-date
    let input = $"" | block-edit $"scratch-XXX.($type)" | lines
    let content = $input | range 1.. | str join (char newline)
    let d = {
        title: ($input | first)
        type: $type
        content: $content
        created: $now
        updated: $now
    }
    run $"insert into scratch \(($d | columns | str join ',')\)
        values \(($d | values | each {Q $in} | str join ',')\)
        returning id;"
    $content
}

export def scratch-edit [id?:int@cmpl-scratch-id --type(-t):string='md'] {
    let id = if ($id | is-empty) {
        run $"select id from scratch order by updated desc limit 1;"
        | get 0.id
    } else {
        $id
    }
    let old = run $"select title, type, content from scratch where id = ($id);"
    let type = if ($type | is-empty) { $old.type | first } else { $type }
    let input = [...$old.title ...$old.content]
    | str join (char newline)
    | block-edit $"scratch-XXX.($type)"
    | lines
    let content = $input | range 1.. | str join (char newline)
    let d = {
        title: ($input | first)
        content: $content
        type: $type
        updated: (date now | fmt-date)
    }
    | items {|k,v|
        $"($k) = (Q $v)"
    }
    | str join ','
    run $"update scratch set ($d) where id = ($id) returning id;"
    $content
}

export def scratch-out [id?:int@cmpl-scratch-id] {
    let id = if ($id | is-empty) {
        run $"select id from scratch order by updated desc limit 1;"
        | get 0.id
    } else {
        $id
    }
    run $"select content from scratch where id = ($id);" | get 0.content
}
