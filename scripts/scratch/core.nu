use libs *
use common.nu *
use completion.nu *
use format.nu *
export use tag.nu *


export def scratch-list [
    ...xtags:string@cmpl-tag-3
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
    --done(-x):int
    --untagged(-U)
    --md(-m)
    --md-list(-l)
    --raw
    --indent: int=2
    --body-lines: int=2
    --scratch-tree
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

    mut cond = ['parent_id = -1']

    # (not $trash) hide deleted
    let exclude_deleted = ["scratch.deleted = ''", "scratch.deleted != ''"]
    # ($tags | is-empty) tags.hidden = 0
    let exclude_tags_hidden = "tags.hidden = 0"
    # ($untagged)
    let include_untagged = "tags.name is null"
    dbg $debug {trash: $trash, notags: ($xtags | is-empty), untagged: $untagged} -t cond
    $cond ++= match [($xtags | is-empty) $untagged] {
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

    let tags = $xtags | tag-group

    if ($xtags | is-not-empty) {
        let tags = $tags.or
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

    mut $time_cond = []
    if ($updated | is-not-empty) { $time_cond ++= $"updated >= ($now - $updated | fmt-date | Q $in)"}
    if ($created | is-not-empty) { $time_cond ++= $"created >= ($now - $created | fmt-date | Q $in)"}
    if ($deadline | is-not-empty) { $time_cond ++= $"deadline >= ($now - $deadline | fmt-date | Q $in)"}
    let time_cond = $time_cond | str join ' or ' | if ($in | is-not-empty) { $"\(($in)\)" }
    if ($time_cond | is-not-empty) { $cond ++= $time_cond }

    if ($relevant | is-not-empty) { $cond ++= $"relevant = ($relevant)"}
    if ($done == 0) { $cond ++= $"done = 0" }
    if ($done == 1) { $cond ++= $"done = 1" }

    let $cond = if ($cond | is-empty) { '' } else { $cond | str join ' and ' | $"where ($in)" }

    let stmt = $"with (tag-tree), root as \(
        select ($fields) from scratch
        left outer join scratch_tag on scratch.id = scratch_tag.scratch_id
        left outer join tags on scratch_tag.tag_id = tags.id
        ($cond) order by ($sort)
    \), r as \(
        select * from root
        union all
        select s.id, s.parent_id, s.title, s.body,
            ($sortable | each { $"s.($in)" } | str join ', '),
            s.relevant, null as tag
        from scratch as s join r on r.id = s.parent_id
    \) select * from r;"

    dbg $debug $stmt -t stmt
    let r = sqlx $stmt
    | group-by id
    | items {|k, x|
        let t = $x
        | get tag
        | filter { $in | is-not-empty }
        | each {$in | default '' | split row ':'}
        $x | first | reject tag | insert tags $t
    }

    let r = if ($tags.and | is-not-empty) or ($tags.not | is-not-empty) {
        $r
        | filter {|x|
            let dt = $x.tags | each { $in | str join ':' }
            let n = not ($tags.not | any {|i| $dt | any {|j| $j | str starts-with $i } })
            let a = $tags.and | all {|i| $dt | any {|j| $j | str starts-with $i } }
            $n and $a
        }
    } else {
        $r
    }

    if $raw {
        $r
    } else if $scratch_tree {
        $r | scratch-format --indent $indent --body-lines $body_lines --md=$md --md-list=$md_list
    } else {
        $r | tag-format $tags.or --indent $indent --body-lines $body_lines --md=$md --md-list=$md_list
    }
}


export def scratch-add [
    ...xargs:string@cmpl-tag-1
    --kind(-k): string@cmpl-kind='md'
    --config: record
    --preset: string
    --parent(-p): int@cmpl-scratch-id
    --important(-i): int
    --urgent(-u): int
    --challenge(-c): int
    --deadline(-d): duration
    --done(-x)
    --relevant(-r): int@cmpl-relevant-id
    --batch
    --returning-body
    --locate-body
    --ignore-empty-body
] {
    let body = $in
    let cfg = if ($config | is-empty) { get-config $kind } else { $config }

    let xargs = $xargs | tag-group
    let tags = $xargs.or
    let title = $xargs.other | str join ' '
    let d = $body | entity --batch=$batch $cfg --title $title --created --locate-body=$locate_body
    if ($d.body | is-empty) and $ignore_empty_body { return }

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
        scratch-ensure-tags $tags | scratch-tagged $id
    }

    if ($preset | is-not-empty) {
        sqlx $"insert into scratch_preset \(scratch_id, preset\)
            VALUES \(($id), (Q $preset)\)"
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
    --config: record
    --preset: string
    --returning-body
    --locate-body
] {
    let body = $in
    let old = sqlx $"select title, kind, body from scratch where id = ($id)" | get -i 0
    let cfg = if ($config | is-empty) {
        let kind = if ($kind | is-empty) { $old.kind } else { $kind }
        get-config $kind
    } else {
        $config
    }
    let body = if ($body | is-empty) { $old.body } else {
        $"<<<<<<< STDIN \n($body)\n=======\n($old.body)"
    }

    let d = $body | entity $cfg --title $old.title --locate-body=$locate_body

    let e = $d | items {|k,v| $"($k) = (Q $v)" } | str join ','
    let id = sqlx $"update scratch set ($e) where id = ($id) returning id;" | get 0.id

    if ($preset | is-not-empty) {
        sqlx $"insert into scratch_preset \(scratch_id, preset\)
            VALUES \(($id), (Q $preset)\) on conflict \(scratch_id\) do update
            set preset=EXCLUDED.preset"
    }

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
    ...xargs: any@cmpl-tag-2
    --important(-i): int
    --urgent(-u): int
    --challenge(-c): int
    --parent(-p): int@cmpl-scratch-id
    --deadline(-d): duration
    --done(-x): int
] {
    let ids = $xargs | filter { ($in | describe) == 'int' }
    let xtags = $xargs | filter { ($in | describe) != 'int' }

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

    if ($xtags | is-not-empty) {
        let tags = $xtags | tag-group
        if ($tags.and | is-not-empty) {
            let tids = scratch-ensure-tags $tags.and
            for id in $ids {
                $tids | scratch-tagged $id
            }
        }
        if ($tags.not | is-not-empty) {
            let tids = sqlx $"with (tag-tree) select tags.id from tags
                where name in \(($tags.not | each {Q $in} | str join ',')\)
            " | get id
            for id in $ids {
                $tids | scratch-untagged $id
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
        sqlx $"with x as \(
            select id from scratch
            left outer join scratch_tag on scratch.id = scratch_id
            where tag_id is null
        \) delete from scratch where id in \(select id from x\) "
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

export def scratch-title [id: int@cmpl-scratch-id] {
    sqlx $'select title from scratch where id = ($id);'
    | get 0.title
}

export def scratch-body [id: int@cmpl-scratch-id] {
    sqlx $'select body from scratch where id = ($id);'
    | get 0.body
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
    sqlx $"select id, kind, title, body from \(
            select id, kind, title, body, created from scratch
            left outer join scratch_tag on scratch.id = scratch_id
            where ($i | str join ' and ')
            union
            select id, kind, title, body, created from scratch
            left outer join scratch_tag on scratch.id = scratch_id
            where ($r | str join ' and ')
        \) as t
        order by t.created desc limit ($num)
    "
    | reduce -f {} {|it,acc|
        let c = $"### ($it.title) [($it.kind)]\n\n($it.body)\n"
        $acc | insert ($it.id | into string) $c
    }
}

export def scratch-in [
    id?:int@cmpl-untagged-scratch-id
    --kind(-k):string@cmpl-kind
    --preset(-p):string@cmpl-kind-preset
] {
    let body = $in
    if ($id | is-empty) {
        let kind = if ($kind | is-empty) { 'md' } else { $kind }
        let cfg = get-config $kind
        $body
        | scratch-add --config $cfg --preset $preset --returning-body --locate-body --ignore-empty-body
        | performance $cfg --preset $preset
    } else {
        let x = sqlx $"select s.kind, p.preset from scratch as s
            left join scratch_preset as p on s.id = p.scratch_id
            where s.id = ($id);" | get -i 0
        let kind = if ($kind | is-empty) { $x.kind } else { $kind }
        let preset = if ($preset | is-empty) { $x.preset } else { $preset }
        let cfg = get-config $kind
        $body
        | scratch-edit $id --config $cfg --preset $preset --returning-body --locate-body
        | performance $cfg --preset $preset
    }
}

export def scratch-out [
    id?:int@cmpl-untagged-scratch-id
    --kind(-k):string@cmpl-kind
    --preset(-p):string@cmpl-kind-preset
    --search(-s): string
    --num(-n):int = 20
] {
    let stdin = $in | default ''
    if ($search | is-not-empty) {
        scratch-search --untagged --num=$num $search
    } else {
        let id = if ($id | is-empty) {
            sqlx $"select id from scratch order by updated desc limit 1;"
            | get 0.id
        } else {
            $id
        }
        let x = sqlx $"select s.body, s.kind, p.preset from scratch as s
            left join scratch_preset as p on s.id = p.scratch_id
            where s.id = ($id);" | get -i 0
        let kind = if ($kind | is-empty) { $x.kind } else { $kind }
        let cfg = get-config $kind
        let preset = if ($preset | is-empty) { $x.preset } else { $preset }
        $x.body | performance $cfg $stdin --preset $preset
    }
}

