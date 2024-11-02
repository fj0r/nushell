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
    let sortable = [
        created, updated, deadline,
        done, important, urgent, challenge
    ]
    let fields = [
        "scratch.id as id", "scratch.parent_id as parent_id",
        title, body, ...$sortable, relevant,
        "tags.name as tag"
    ] | str join ', '

    let sort = if ($sort | is-empty) { ['created'] } else { $sort }
    | each { $"scratch.($in)" }
    | str join ', '

    mut cond = []

    # (not $trash) hide deleted
    let exclude_deleted = ["scratch.deleted = ''", "scratch.deleted != ''"]
    # ($tags | is-empty) tags.hidden = 0
    let exclude_tags_hidden = "tags.hidden = 0"
    # ($untagged)
    let include_untagged = "tags.name is null"
    dbg $debug {trash: $trash, notags: ($tags | is-empty), untagged: $untagged} -t cond
    $cond ++= match [($tags | is-empty) $untagged] {
        # --untagged
        [true true] => $include_untagged
        #
        [true false] => $exclude_tags_hidden
        # [ --untagged tag ]
        [false true] => $include_untagged
        # tag
        [false false] => ""
    }
    | do { let x = $in
        [($exclude_deleted | get ($trash | into int)) $x]
        | filter { $in | is-not-empty}
        | str join ' and '
    }

    mut flt = {and:[], not:[]}
    if ($tags | is-not-empty) {
        $flt = $tags | tag-group
        let tags = $flt.normal
        let tags_id = sqlx $"with (tag-tree), tid as \(
            select id from tags where name in \(($tags | each {Q $in} | str join ', ')\)
        \), (tag-branch ids --where 'id in (select id from tid)')
        select id from ids"
        | get id | each { $in | into string } | str join ', '
        $cond ++= $"scratch.id in \(select scratch_id from scratch_tag where tag_id in \(($tags_id)\)\)"
    }

    let now = date now
    if ($search | is-not-empty) { $cond ++= $"title like '%($search)%'" }
    if ($challenge | is-not-empty) { $cond ++= $"challenge >= ($challenge)"}
    if ($important | is-not-empty) { $cond ++= $"important >= ($important)"}
    if ($urgent | is-not-empty) { $cond ++= $"urgent >= ($urgent)"}
    if ($updated | is-not-empty) { $cond ++= $"updated >= ($now - $updated | fmt-date | Q $in)"}
    if ($created | is-not-empty) { $cond ++= $"created >= ($now - $created | fmt-date | Q $in)"}
    if ($deadline | is-not-empty) { $cond ++= $"deadline >= ($now - $deadline | fmt-date | Q $in)"}
    if ($relevant | is-not-empty) { $cond ++= $"relevant = ($relevant)"}
    if ($work_in_process) { $cond ++= $"done = 0" }
    if ($finished) { $cond ++= $"done = 1" }

    let $cond = if ($cond | is-empty) { '' } else { $cond | str join ' and ' | $"where ($in)" }

    let stmt = $"with (tag-tree) select ($fields) from scratch
        left outer join scratch_tag on scratch.id = scratch_tag.scratch_id
        left outer join tags on scratch_tag.tag_id = tags.id
        ($cond) order by ($sort);"
    dbg $debug $stmt -t stmt
    let r = sqlx $stmt
    | group-by id
    | items {|k, x| $x | first | insert tags ($x | get tag) | reject tag }

    let flt = $flt
    let r = if ($flt.and | is-not-empty) or ($flt.not | is-not-empty) {
        $r
        | filter {|x|
            let n = not ($flt.not | any {|y| $y in $x.tags })
            let a = $flt.and | all {|y| $y in $x.tags }
            $n and $a
        }
    } else {
        $r
    }


    if $raw {
        $r
    } else {
        if $no_branch {
            $r
        } else {
            let ids = $r | get id | str join ', '
            let fp = [id, parent_id, title]
            let ft = $fp | each { $"t.($in)" } | str join ', '
            let x = sqlx $"with recursive p as \(
                select ($fp | str join ', '), 2 as done from scratch where id in \(($ids)\)
                union all
                select ($ft), 2 as done from scratch as t join p on p.parent_id = t.id
                \) select * from p;"
            $r | append $x | uniq-by id
        }
        | scratch-format --md=$md --md-list=$md_list
    }
}


export def scratch-add [
    ...tags:string@cmpl-tag
    --title(-t): string=""
    --kind(-k): string@cmpl-kind='md'
    --parent(-p): int@cmpl-scratch-id
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

    let d = $body | entity --batch=$batch $cfg --title $title --kind $kind --created
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

    let d = {...$d, ...$attrs}

    let id = sqlx $"insert into scratch \(($d | columns | str join ',')\)
        values \(($d | values | each {Q $in} | str join ',')\)
        returning id;" | get 0.id

    if ($tags | is-not-empty) {
        scratch-ensure-tags $tags
        let children = $"select ($id), tags.id from tags where name in \(($tags | each {Q $in} | str join ',')\)"
        sqlx $"with (tag-tree) insert into scratch_tag ($children)
          on conflict \(scratch_id, tag_id\) do nothing
        ;"
    }

    scratch-done $id --reverse=(not $done)

    if $returning_body {
        $d.body
    } else {
        $id
    }
}

export def scratch-edit [
    id:int@cmpl-scratch-id
    --kind(-k):string@cmpl-kind
    --returning-body
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
    let id = sqlx $"update scratch set ($e) where id = ($id) returning id;" | get 0.id

    if $returning_body {
        $d.body
    } else {
        $id
    }
}

export def scratch-delete [
    ...id: int@cmpl-scratch-id
    --reverse(-r)
] {
    let now = date now | fmt-date | Q $in
    let d = if $reverse { '' } else { $now }
    let ids = $id | str join ','
    let pid = sqlx $"update scratch set deleted = ($d) where id in \(($ids)\) returning parent_id;" | get parent_id
    # update parents status
    for i in $pid {
        uplevel done $i $now (not $reverse)
    }
}

export def scratch-attrs [
    ...ids: int@cmpl-scratch-id
    --important(-i): int
    --urgent(-u): int
    --challenge(-c): int
    --parent(-p): int@cmpl-scratch-id
    --deadline(-d): duration
    --done(-x): int
    --tag(-t): list<string@cmpl-tag>
    --remove(-r)
] {
    let args = {
        important: $important
        urgent: $urgent
        challenge: $challenge
        parent_id: $parent
        deadline: (if ($deadline | is-not-empty) {(date now) + $deadline | fmt-date})
    }
    | filter-empty

    if ($args | is-not-empty) {
        let attrs = $args
        | items {|k, v| $"($k) = (Q $v)"}
        | str join ','
        sqlx $"update scratch set ($attrs) where id in \(($ids | str join ',')\);"
    }

    if ($done | is-not-empty) {
        for id in $ids {
            scratch-done $id --reverse=($done == 0)
        }
    }

    if ($tag | is-not-empty) {
        scratch-ensure-tags $tag
        if $remove {
            let children = sqlx $"with (tag-tree) select tags.id from tags where name in \(($tag | each {Q $in} | str join ',')\)" | get id
            sqlx $"delete from scratch_tag where scratch_id in \(($ids | str join ',')\) and tag_id in \(($children | str join ',')\);"
        } else {
            for id in $ids {
                let children = $"select ($id), tags.id from tags where name in \(($tag | each {Q $in} | str join ',')\)"
                sqlx $"with (tag-tree) insert into scratch_tag ($children)
                  on conflict \(scratch_id, tag_id\) do nothing
                ;"
            }
        }
    }
}

export def scratch-done [
    ...id: int@cmpl-scratch-id
    --reverse(-r)
] {
    let d = if $reverse { 0 } else { 1 }
    let now = date now | fmt-date | Q $in
    let ids = $id | str join ','
    let pid = sqlx $"update scratch set done = ($d), updated = ($now) where id in \(($ids)\) returning parent_id;" | get parent_id
    # update parents status
    for i in $pid {
        uplevel done $i $now (not $reverse)
    }
}

export def scratch-move [
    id: int@cmpl-scratch-id
    to: int@cmpl-scratch-id
] {
    let now = date now | fmt-date | Q $in
    let pid = sqlx $"select parent_id from scratch where id = ($id);" | get 0.parent_id
    sqlx $"update scratch set parent_id = ($to) where id = ($id);"
    uplevel done $pid $now true
    uplevel done $to $now true
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
        let tags = sqlx $"delete from scratch_tag where scratch_id in \(select id from scratch where deleted != ''\) returning scratch_id, tag_id"
        let scratch = sqlx $"delete from scratch where deleted != '' returning id"
        {
            scratch: $scratch
            scratch_tags: $tags
        }
    }
}

export def scratch-search [
    keyword
    --num(-n):int = 20
    --untagged
] {
    let k = Q $"%($keyword)%"
    mut i = [$"title like ($k)"]
    mut r = [$"body like ($k)"]
    if $untagged {
        $i ++= 'tag_id is null'
        $r ++= 'tag_id is null'
    }
    sqlx $"select id, title, body from \(
            select id, title, body, created from scratch
            left outer join scratch_tag on scratch.id = scratch_id
            where ($i | str join ' and ')
            union
            select id, title, body, created from scratch
            left outer join scratch_tag on scratch.id = scratch_id
            where ($r | str join ' and ')
        \) as t
        order by t.created desc limit ($num)
    "
    | reduce -f {} {|it,acc|
        let c = $"### ($it.title)\n\n($it.body)\n"
        $acc | insert ($it.id | into string) $c
    }
}

export def scratch-in [
    id?:int@cmpl-untagged-scratch-id
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
        $o | scratch-edit --kind=$kind $id --returning-body | performance $cfg
    }
}

export def scratch-out [
    id?:int@cmpl-untagged-scratch-id
    --kind(-k):string@cmpl-kind
    --search(-s): string
    --num(-n):int = 20
] {
    let o = $in | default ''
    if ($search | is-not-empty) {
        scratch-search --untagged --num=$num $search
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

