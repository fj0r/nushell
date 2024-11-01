use common.nu *

def cmpl-scratch-id [] {
    run $"select id as value, updated || '│' || type || '│' ||
        case title when '' then '...' || substr\(ltrim\(content\), 0, 20\) else title end  as description
        from scratch order by updated desc limit 10;"
}

export def scratch-add [--type(-t): string@cmpl-type='md'] {
    let o = $in
    let now = date now | fmt-date
    let cfg = get-config $type
    let content = if ($o | is-empty) { char newline } else { $o }
    let input = $"('' | from title $cfg)\n($content)"
    | block-edit $"scratch-XXX.($type)" --type $type --line 2
    | lines
    let content = $input | range 1.. | skip-empty-lines | str join (char newline)
    if ($content | is-empty) { return }
    let d = {
        title: ($input | first | to title $cfg)
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

export def scratch-edit [
    id:int@cmpl-scratch-id
    --type(-t):string@cmpl-type='md'
] {
    let o = $in
    let cfg = get-config $type
    let old = run $"select title, type, content from scratch where id = ($id)"
    | get -i 0
    let type = if ($type | is-empty) { $old.type | first } else { $type }
    let now = date now | fmt-date
    let content = if ($o | is-empty) { $old.content } else {
        $"($o)\n>>>>>>($now)<<<<<<\n($old.content)"
    }
    let title = $old.title | from title $cfg
    let input = [$title $content]
    | str join (char newline)
    | block-edit $"scratch-XXX.($type)" --type $type --line 2
    | lines
    let content = $input | range 1.. | skip-empty-lines | str join (char newline)
    let d = {
        title: ($input | first | to title $cfg)
        content: $content
        type: $type
        updated: $now
    }
    | items {|k,v|
        $"($k) = (Q $v)"
    }
    | str join ','
    run $"update scratch set ($d) where id = ($id) returning id;"
    $content
}

export def scratch-search [keyword --num(-n):int = 20] {
    let k = Q $"%($keyword)%"
    run $"select id, title, content from \(
            select id, title, content, created from scratch where title like ($k)
            union
            select id, title, content, created from scratch where content like ($k)
        \) as t
        order by t.created desc limit ($num)
    "
    | reduce -f {} {|it,acc|
        let c = $"### ($it.title)\n\n($it.content)\n"
        $acc | insert ($it.id | into string) $c
    }
}

export def scratch-clean [
    --untitled
] {
    if $untitled {
        run "delete from scratch where title = '' returning id, content"
        | reduce -f {} {|it,acc| $acc | insert ($it.id | into string) $it.content }
    }
}

export def scratch-in [
    id?:int@cmpl-scratch-id
    --type(-t):string@cmpl-type
] {
    let o = $in
    if ($id | is-empty) {
        let type = if ($type | is-empty) { 'md' } else { $type }
        let cfg = get-config $type
        $o | scratch-add --type=$type | performance $cfg
    } else {
        let x = run $"select type from scratch where id = ($id);" | get -i 0
        let type = if ($type | is-empty) { $x.type } else { $type }
        let cfg = get-config $type
        $o | scratch-edit --type=$type $id | performance $cfg
    }
}

export def scratch-out [
    id?:int@cmpl-scratch-id
    --type(-t):string@cmpl-type
    --search(-s): string
    --num(-n):int = 20
] {
    let o = $in | default ''
    if ($search | is-not-empty) {
        scratch-search --num=$num $search
    } else {
        let id = if ($id | is-empty) {
            run $"select id from scratch order by updated desc limit 1;"
            | get 0.id
        } else {
            $id
        }
        let x = run $"select content, type from scratch where id = ($id);" | get -i 0
        let type = if ($type | is-empty) { $x.type } else { $type }
        let cfg = get-config $type
        $x.content | performance $cfg $o
    }
}

