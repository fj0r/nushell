use libs *
use completion.nu *
export def scratch-list [
    ...tags:string@cmpl-tag
    --search(-s): string
    --trash(-T) # show trash
    --important(-i): int
    --urgent(-u): int
    --challenge(-c): int
    --updated: duration
    --created: duration
    --deadline: duration
    --relevant(-r): int@cmpl-relevant-id
    --sort(-s): list<string@cmpl-sort>
    --work-in-process(-W)
    --finished(-F)
    --untagged(-U)
    --no-branch(-N)
    --md(-m)
    --md-list(-l)
    --raw
    --debug
] {

}

export def scratch-add [
    ...tags:string@cmpl-tag
    --title(-t): string
    --body(-b): string
    --kind(-k): string@cmpl-kind='md'
    --important(-i): int@cmpl-level
    --urgent(-u): int@cmpl-level
    --challenge(-c): int@cmpl-level
    --deadline(-d): duration
    --done(-x)
    --relevant(-r): int@cmpl-relevant-id
] {
    let o = $in
    let now = date now | fmt-date
    let cfg = get-config $kind
    let body = if ($o | is-empty) { char newline } else { $o }
    let input = $"('' | from title $cfg)\n($body)"
    | block-edit $"scratch-XXX.($kind)" ($cfg | update pos {|x| $x.pos + 1 })
    | lines
    let body = $input | range 1.. | skip-empty-lines | str join (char newline)
    if ($body | is-empty) { return }
    let d = {
        title: ($input | first | to title $cfg)
        kind: $kind
        body: $body
        created: $now
        updated: $now
    }
    run $"insert into scratch \(($d | columns | str join ',')\)
        values \(($d | values | each {Q $in} | str join ',')\)
        returning id;"
    $body
}

export def scratch-edit [
    id:int@cmpl-scratch-id
    --kind(-k):string@cmpl-kind='md'
] {
    let o = $in
    let cfg = get-config $kind
    let old = run $"select title, kind, body from scratch where id = ($id)"
    | get -i 0
    let kind = if ($kind | is-empty) { $old.kind | first } else { $kind }
    let now = date now | fmt-date
    let body = if ($o | is-empty) { $old.body } else {
        $"($o)\n>>>>>>($now)<<<<<<\n($old.body)"
    }
    let title = $old.title | from title $cfg
    let input = [$title $body]
    | str join (char newline)
    | block-edit $"scratch-XXX.($kind)" ($cfg | update pos {|x| $x.pos + 1 })
    | lines
    let body = $input | range 1.. | skip-empty-lines | str join (char newline)
    let d = {
        title: ($input | first | to title $cfg)
        body: $body
        kind: $kind
        updated: $now
    }
    | items {|k,v|
        $"($k) = (Q $v)"
    }
    | str join ','
    run $"update scratch set ($d) where id = ($id) returning id;"
    $body
}

export def scratch-search [keyword --num(-n):int = 20] {
    let k = Q $"%($keyword)%"
    run $"select id, title, body from \(
            select id, title, body, created from scratch where title like ($k)
            union
            select id, title, body, created from scratch where body like ($k)
        \) as t
        order by t.created desc limit ($num)
    "
    | reduce -f {} {|it,acc|
        let c = $"### ($it.title)\n\n($it.body)\n"
        $acc | insert ($it.id | into string) $c
    }
}

export def scratch-clean [
    --untitled
    --untagged
    --deleted
] {
    if $untitled {
        run "delete from scratch where title = '' returning id, body"
        | reduce -f {} {|it,acc| $acc | insert ($it.id | into string) $it.body }
    }
    if $untagged {

    }
    if $deleted {

    }
}

export def scratch-in [
    id?:int@cmpl-scratch-id
    --kind(-k):string@cmpl-kind
] {
    let o = $in
    if ($id | is-empty) {
        let kind = if ($kind | is-empty) { 'md' } else { $kind }
        let cfg = get-config $kind
        $o | scratch-add --kind=$kind | performance $cfg
    } else {
        let x = run $"select kind from scratch where id = ($id);" | get -i 0
        let kind = if ($kind | is-empty) { $x.kind } else { $kind }
        let cfg = get-config $kind
        $o | scratch-edit --kind=$kind $id | performance $cfg
    }
}

export def scratch-out [
    id?:int@cmpl-scratch-id
    --kind(-k):string@cmpl-kind
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
        let x = run $"select body, kind from scratch where id = ($id);" | get -i 0
        let kind = if ($kind | is-empty) { $x.kind } else { $kind }
        let cfg = get-config $kind
        $x.body | performance $cfg $o
    }
}

