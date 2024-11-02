use libs *
use common.nu *
use completion.nu *
export use tag.nu *


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
    --parent(-p): int@cmpl-sid
    --important(-i): int
    --urgent(-u): int
    --challenge(-c): int
    --deadline(-d): duration
    --done(-x)
    --relevant(-r): int@cmpl-relevant-id
    --returning-body
    --batch
] {
    let o = $in
    let cfg = get-config $kind
    let body = if ($o | is-empty) { char newline } else { $o }

    let d = $body | entity --batch=$batch $cfg --title "" --kind $kind --created
    if ($d.body | is-empty) { return }

    let attrs = {
        important: $important
        urgent: $urgent
        challenge: $challenge
        parent_id: $parent
        relevant: $relevant
        deadline: (if ($deadline | is-not-empty) {(date now) + $deadline | fmt-date})
        done: (if $done { 1 } else { 0 })
    } | filter-empty

    let id = sqlx $"insert into scratch \(($d | columns | str join ',')\)
        values \(($d | values | each {Q $in} | str join ',')\)
        returning id;" | get 0.id

    if $returning_body {
        $d.body
    } else {
        $id
    }
}

export def scratch-edit [
    id:int@cmpl-scratch-id
    --kind(-k):string@cmpl-kind
] {
    let o = $in
    let old = sqlx $"select title, kind, body from scratch where id = ($id)" | get -i 0
    let kind = if ($kind | is-empty) { $old.kind } else { $kind }
    let cfg = get-config $kind
    let body = if ($o | is-empty) { $old.body } else {
        $"($o)\n>>>>>>\n($old.body)"
    }

    let d = $body | entity $cfg --title $old.title --kind $kind

    let e = $d
    | items {|k,v| $"($k) = (Q $v)" }
    | str join ','
    sqlx $"update scratch set ($e) where id = ($id) returning id;"

    $d.body
}

export def scratch-search [keyword --num(-n):int = 20] {
    let k = Q $"%($keyword)%"
    sqlx $"select id, title, body from \(
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
        sqlx "delete from scratch where title = '' returning id, body"
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
        $o | scratch-add --kind=$kind --returning-body | performance $cfg
    } else {
        let x = sqlx $"select kind from scratch where id = ($id);" | get -i 0
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
            sqlx $"select id from scratch order by updated desc limit 1;"
            | get 0.id
        } else {
            $id
        }
        let x = sqlx $"select body, kind from scratch where id = ($id);" | get -i 0
        let kind = if ($kind | is-empty) { $x.kind } else { $kind }
        let cfg = get-config $kind
        $x.body | performance $cfg $o
    }
}

