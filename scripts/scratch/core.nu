use libs *
use common.nu *
use libs/convert.nu *
use completion.nu *
use format.nu *
use tag_base.nu *
use tag.nu *


export def scratch-list [
    ...xtags:string@cmpl-tag-3
    --search(-s): string
    --trash(-T) # show trash
    --hidden(-H)
    --important(-i): int
    --urgent(-u): int
    --challenge(-c): int
    --updated: duration
    --created: duration
    --deadline: duration
    --relevant(-r): int@cmpl-relevant-id
    --sort: list<string@cmpl-sort>
    --done(-x):int
    --raw
    --md(-m)
    --md-list(-l)
    --indent: int=2
    --body-lines: int=2
    --scratch-tree
    --debug
    --accumulator(-a): any
] {
    let tags = $xtags | tags-group

    let sortable = [
        value, done, kind,
        created, updated, deadline,
        important, urgent, challenge
    ]
    let fields = [
        "scratch.id as id", "scratch.parent_id as parent_id",
        title, body, ...$sortable, relevant,
        "tags.name as tag"
    ] | str join ', '

    let sort = if ($sort | is-empty) { ['updated'] } else { $sort }
    | each {|x|
        if ($x | str starts-with '!') {
            $"($x | str substring 1..) desc"
        } else {
            $x
        }
    }
    | str join ', '

    mut cond = ['parent_id = -1' 'tags.id is not null']
    mut exist_tagsid = []

    $cond ++= if $trash { ["scratch.deleted != ''"] } else { ["scratch.deleted = ''"] }

    if ($tags.or | is-not-empty) {
        let tags_id = scratch-tag-paths-id ...$tags.or
        | each { $in.data | last | get id }
        | scratch-tags-children ...$in
        $exist_tagsid ++= $tags_id
        let tags_id = $tags_id | each { $in | into string } | str join ', '
        $cond ++= [$"scratch.id in \(select scratch_id from scratch_tag where tag_id in \(($tags_id)\)\)"]
    }

    if ($tags.and | is-not-empty) {
        let tags_id = scratch-tag-paths-id ...$tags.and
        | each { $in.data | last | get id }
        | scratch-tags-children ...$in
        $exist_tagsid ++= $tags_id
        let tags_id = $tags_id | each { $in | into string } | str join ', '
        $cond ++= [$"scratch.id in \(select scratch_id from scratch_tag where tag_id in \(($tags_id)\)\)"]
    }

    if ($tags.not | is-not-empty) {
        let tags_id = scratch-tag-paths-id ...$tags.not
        | each { $in.data | last | get id }
        | scratch-tags-children ...$in
        | each { $in | into string } | str join ', '
        $cond ++= [$"scratch.id not in \(select scratch_id from scratch_tag where tag_id in \(($tags_id)\)\)"]
    }

    if not $hidden {
        let tags_id = sqlx "select id from tag where hidden = 1"
        | get id
        | scratch-tags-children ...$in
        let exist_tagsid = $exist_tagsid
        let tags_id = $tags_id
        | filter {|x| $x not-in $exist_tagsid }
        | each { $in | into string } | str join ', '
        $cond ++= [$"scratch.id not in \(select scratch_id from scratch_tag where tag_id in \(($tags_id)\)\)"]
    }


    let now = date now
    if ($search | is-not-empty) { $cond ++= [$"lower\(title\) glob lower\('*($search)*'\)"] }
    if ($challenge | is-not-empty) { $cond ++= [$"challenge >= ($challenge)"] }
    if ($important | is-not-empty) { $cond ++= [$"important >= ($important)"] }
    if ($urgent | is-not-empty) { $cond ++= [$"urgent >= ($urgent)"] }

    mut $time_cond = []
    if ($updated | is-not-empty) { $time_cond ++= [$"updated >= ($now - $updated | fmt-date | Q $in)"] }
    if ($created | is-not-empty) { $time_cond ++= [$"created >= ($now - $created | fmt-date | Q $in)"] }
    if ($deadline | is-not-empty) { $time_cond ++= [$"\(deadline <= ($now + $deadline | fmt-date | Q $in) and done = 0\)"] }
    let time_cond = $time_cond | str join ' or ' | if ($in | is-not-empty) { $"\(($in)\)" }
    if ($time_cond | is-not-empty) { $cond ++= [$time_cond] }

    if ($relevant | is-not-empty) { $cond ++= [$"relevant = ($relevant)"] }
    match $done {
        0 => { $cond ++= ["done == 0"] }
        1 | 2 => { $cond ++= [$"done >= ($done)"] }
    }

    let $cond = if ($cond | is-empty) { '' } else { $cond | str join ' and ' | $"where ($in)" }

    let stmt = $"with (tag-tree), root as \(
        select ($fields) from scratch
        left outer join scratch_tag on scratch.id = scratch_tag.scratch_id
        left outer join tags on scratch_tag.tag_id = tags.id
        ($cond)
    \), r as \(
        select * from root
        union all
        select s.id, s.parent_id, s.title, s.body,
            ($sortable | each { $"s.($in)" } | str join ', '),
            s.relevant, null as tag
        from scratch as s join r on r.id = s.parent_id
    \) select * from r order by ($sort);"

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


    if $raw {
        $r
    } else if $scratch_tree {
        $r | scratch-format --indent $indent --body-lines $body_lines --md=$md --md-list=$md_list
    } else {
        let acc = match ($accumulator | describe -d).type {
            string => { $env.SCRATCH_ACCUMULATOR | get $accumulator }
            list => {
                $accumulator
                | each {|x| $env.SCRATCH_ACCUMULATOR | get $x }
                | reduce -f {} {|i,a| $a | merge $i }
            }
            record => { $accumulator }
            _ => null
        }
        $r | tag-format $tags.or --indent $indent --body-lines $body_lines --md=$md --md-list=$md_list --accumulator $acc
    }
}


export def scratch-add [
    ...xargs:string@cmpl-tag-1
    --kind(-k): string@cmpl-kind='md'
    --config: record
    --preset(-p): string@cmpl-kind-preset
    --parent(-f): int@cmpl-scratch-id
    --important(-i): int
    --urgent(-u): int
    --challenge(-c): int
    --deadline(-d): duration
    --done(-x): int = 0
    --value(-v): number
    --relevant(-r): int@cmpl-relevant-id
    --batch
    --ignore-empty-body
    --complete
    --perf-ctx: record
    --locate-body
] {
    let body = $in
    let cfg = if ($config | is-empty) { get-config $kind --preset $preset } else { $config }

    let xargs = $xargs | tags-group
    let tags = $xargs.or
    let title = $xargs.other | str join ' '
    let x = $body | entity --batch=$batch $cfg --title $title --created --locate-body=$locate_body --perf-ctx $perf_ctx
    let d = $x.value
    if ($d.body | is-empty) and $ignore_empty_body { return }

    let attrs = {
        important: $important
        urgent: $urgent
        challenge: $challenge
        parent_id: $parent
        relevant: $relevant
        deadline: (if ($deadline | is-not-empty) {(date now) + $deadline | fmt-date})
        value: $value
        done: $done
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

    scratch-done $id --done $done

    if $complete {
        $x
    } else {
        $id
    }
}

export def scratch-edit [
    id:int@cmpl-scratch-id
    --kind(-k):string@cmpl-kind
    --config: record
    --preset(-p): string@cmpl-kind-preset
    --complete
    --locate-body
    --perf-ctx: record
] {
    let body = $in
    let old = sqlx $"select title, kind, body from scratch where id = ($id)" | get -i 0
    let cfg = if ($config | is-empty) {
        let kind = if ($kind | is-empty) { $old.kind } else { $kind }
        get-config $kind --preset $preset
    } else {
        $config
    }
    let body = if ($body | is-empty) { $old.body } else {
        $"<<<<<<< STDIN \n($body)\n=======\n($old.body)"
    }

    let x = $body | entity $cfg --title $old.title --locate-body=$locate_body --perf-ctx $perf_ctx
    let d = $x.value

    let e = $d | items {|k,v| $"($k) = (Q $v)" } | str join ','
    let id = sqlx $"update scratch set ($e) where id = ($id) returning id;" | get 0.id

    if ($preset | is-not-empty) {
        sqlx $"insert into scratch_preset \(scratch_id, preset\)
            VALUES \(($id), (Q $preset)\) on conflict \(scratch_id\) do update
            set preset=EXCLUDED.preset"
    }

    if $complete {
        $x
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
        uplevel done $i $now (not $reverse | into int)
    }
}

export def scratch-attrs [
    ...xargs: any@cmpl-tag-2
    --important(-i): int
    --urgent(-u): int
    --challenge(-c): int
    --parent(-f): int@cmpl-scratch-id
    --deadline(-d): duration
    --done(-x): int
    --value(-v): number
    --adder(-a): number
    --kind(-k):string@cmpl-kind
] {
    let ids = $xargs | filter { ($in | describe) == 'int' }
    let xtags = $xargs | filter { ($in | describe) != 'int' }

    let args = {
        value: $value
        kind: $kind
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

    if ($adder | is-not-empty) and ($adder != 0) {
        let o = if $adder > 0 { $"+ ($adder)" } else { $"- ($adder | math abs)" }
        sqlx $"update scratch set value = value ($o) where id in \(($ids | str join ',')\);"
    }

    if ($done | is-not-empty) {
        for id in $ids {
            scratch-done $id --done $done
        }
    }

    if ($xtags | is-not-empty) {
        let tags = $xtags | tags-group
        if ($tags.and | is-not-empty) {
            let tids = scratch-ensure-tags $tags.and
            for id in $ids {
                $tids | scratch-tagged $id
            }
        }
        if ($tags.not | is-not-empty) {
            let tids = scratch-tag-paths-id ...$tags.not
            | each {|y|
                if $y.present {
                    $y.data | last | get id
                }
            }
            for id in $ids {
                $tids | scratch-untagged $id
            }
        }
    }
}

export def scratch-done [
    ...id: int@cmpl-scratch-id
    --done(-x):int = 1
] {
    let d = $done
    let now = date now | fmt-date | Q $in
    let ids = $id | str join ','
    let pid = sqlx $"update scratch set done = ($d), updated = ($now) where id in \(($ids)\) returning parent_id;" | get parent_id
    # update parents status
    for i in $pid {
        uplevel done $i $now $done
    }
}

export def scratch-move [
    id: int@cmpl-scratch-id
    to: int@cmpl-scratch-id
] {
    let now = date now | fmt-date | Q $in
    let pid = sqlx $"select parent_id from scratch where id = ($id);" | get 0.parent_id
    sqlx $"update scratch set parent_id = ($to) where id = ($id);"
    uplevel done $pid $now 1
    uplevel done $to $now 1
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

export def scratch-title [
    id:int@cmpl-scratch-id
] {
    sqlx $"select title from scratch where id = ($id)"
    | get 0.title
}

export def scratch-data [...xargs: any@cmpl-tag-3] {
    let ids = $xargs | filter { ($in | describe) == 'int' }
    let xtags = $xargs | filter { ($in | describe) != 'int' }

    let tags_id = $xtags | tags-group | get or
    let t = if ($tags_id | is-not-empty) {
        let tags_id = scratch-tag-paths-id ...$tags_id
        | each { $in.data | last | get id }
        | str join ', '

        sqlx $"with recursive g as \(
            select id, parent_id from tag where id in \(($tags_id)\)
            union all
            select t.id, t.parent_id from tag as t join g on g.id = t.parent_id
        \), root as \(
            select s.id, s.parent_id, s.kind, s.title, s.body from g
            join scratch_tag as t on g.id = t.tag_id
            join scratch as s on t.scratch_id = s.id
        \), r as \(
            select * from root
            union all
            select s.id, s.parent_id, s.kind, s.title, s.body
            from scratch as s join r on r.id = s.parent_id
        \) select * from r;"
    }
    let i = sqlx $"select id, parent_id, kind, title, body from scratch where id in \(($ids | str join ', ')\);"

    if ($tags_id | is-empty) {
        $i
    } else {
        let tids = $t | get id
        $t | append ($i | filter {|x| $x.id not-in $tids })
    }
    | update body {|x| $x.body | from-all $x.kind }
}

export def scratch-search [
    keyword
    --num(-n):int = 20
    --untagged
] {
    let k = Q $"*($keyword)*"
    mut i = [$"lower\(title\) glob lower\(($k)\)"]
    mut r = [$"lower\(body\) glob lower\(($k)\)"]
    if $untagged {
        $i ++= ['tag_id is null']
        $r ++= ['tag_id is null']
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
    id?:int@cmpl-untagged-root-scratch          # retrieve by id
    --title(-t):string@cmpl-untagged-root-title # retrieve by title
    --kind(-k):string@cmpl-kind
    --preset(-p):string@cmpl-kind-preset
    --args(-a):list<string>
] {
    let body = $in
    if ($id | is-empty) and ($title | is-empty) {
        let kind = if ($kind | is-empty) { 'md' } else { $kind }
        let cfg = get-config $kind --preset $preset
        let x = $body
        | scratch-add --config $cfg --preset $preset --complete --locate-body --ignore-empty-body --perf-ctx { retain: true, args: $args }
        $x.value.body | performance $cfg --preset $preset --context $x.context --args $args
    } else {
        let c = if ($title | is-empty) { $"s.id = ($id)" } else { $"s.title = (Q $title)" }
        let x = sqlx $"select s.id, s.kind, p.preset from scratch as s
            left join scratch_preset as p on s.id = p.scratch_id
            where ($c);" | get -i 0
        let kind = if ($kind | is-empty) { $x.kind } else { $kind }
        let preset = if ($preset | is-empty) { $x.preset } else { $preset }
        let id = if ($id | is-empty) { $x.id } else { $id }
        let cfg = get-config $kind --preset $preset
        let x = $body
        | scratch-edit $id --config $cfg --preset $preset --complete --locate-body --perf-ctx { retain: true, args: $args }
        $x.value.body | performance $cfg --preset $preset --context $x.context --args $args
    }
}

export def scratch-out [
    id?:int@cmpl-untagged-root-scratch
    --title(-t):string@cmpl-untagged-root-title
    --kind(-k):string@cmpl-kind
    --preset(-p):string@cmpl-kind-preset
    --args(-a):list<string>
    --search(-s): string
    --num(-n):int = 20
] {
    let stdin = $in | default ''
    if ($search | is-not-empty) {
        scratch-search --untagged --num=$num $search
    } else {
        let id = if ($title | is-not-empty) {
            sqlx $"select id, title from scratch where title = (Q $title);"
            | get 0.id
        } else if ($id | is-not-empty) {
            $id
        } else {
            sqlx $"select id from scratch order by updated desc limit 1;"
            | get 0.id
        }
        let x = sqlx $"select s.body, s.kind, p.preset from scratch as s
            left join scratch_preset as p on s.id = p.scratch_id
            where s.id = ($id);" | get -i 0
        let kind = if ($kind | is-empty) { $x.kind } else { $kind }
        let cfg = get-config $kind --preset $preset
        let preset = if ($preset | is-empty) { $x.preset } else { $preset }
        $x.body | performance $cfg $stdin --preset $preset --args $args
    }
}


export def scratch-flush [
    id?:int@cmpl-untagged-root-scratch
    --title(-t):string@cmpl-untagged-root-title
    --kind(-k):string@cmpl-kind
    --preset(-p):string@cmpl-kind-preset
] {
    let o = $in
    if ($id | is-empty) and ($title | is-empty) {
        error make -u { msg: 'id and title cannot both be empty' }
    }

    let c = if ($title | is-empty) { $"id = ($id)" } else { $"title = (Q $title)" }
    let r = sqlx $"select id, title, kind from scratch where ($c);"

    let sid = $r | get -i 0.id

    let kind = if ($kind | is-empty) {
        $r | get -i 0.kind | default 'md'
    } else {
        $kind
    }

    let title = if ($title | is-empty) {
        $r | get -i 0.title
    } else {
        $title
    }

    {
        id: $sid
        body: ($o | to-all $kind)
        kind: $kind
        title: $title
        preset: $preset
    }
    | filter-empty
    | db-upsert scratch id
    $sid
}

export def scratch-upsert-kind [
    name?: string@cmpl-kind
    --delete
    --batch
] {
    let x = if ($name | is-empty) {
        {}
    } else {
        sqlx $"select * from kind where name = (Q $name)" | get -i 0
    }
    $x | upsert-kind --delete=$delete --action {|config|
        let o = $in
        if $batch {
            $o
        } else {
            $o
            | to yaml
            | $"# ($config.pk| str join ', ') is the primary key, do not modify it\n($in)"
            | block-edit $"scratch-kind-XXXXXX.yaml"
            | from yaml
        }
    }
}

export def scratch-upsert-preset [
    kind?: string@cmpl-kind
    name?: string@cmpl-kind-preset
    --delete
    --batch
] {
    let x = if ($kind | is-empty) {
        {}
    } else {
        sqlx $"select * from kind_preset where kind = (Q $kind) and name = (Q $name)" | get -i 0
    }
    $x | upsert-kind-preset --delete=$delete --action {|config|
        let o = $in
        if $batch {
            $o
        } else {
            $o
            | to yaml
            | $"# ($config.pk| str join ', ') is the primary key, do not modify it\n($in)"
            | block-edit $"scratch-preset-XXXXXX.yaml"
            | from yaml
        }
    }
}

export def scratch-editor-run [
    --watch(-w)
    --clear(-c)
    --args(-a): list<string>
    transform?:closure
] {
    let ctx = $env.SCRATCH_EDITOR_CONTEXT?
    if ($ctx | is-empty) { error make -u { msg: "Must be run in the Scratch editor" } }
    let ctx = $ctx | from nuon
    let ctx = if ($args | is-empty) { $ctx } else { $ctx | upsert args $args }
    let transform = $transform | default {|x| print $x }
    do $transform (run-cmd $ctx)
    if $watch {
        watch . -g $ctx.entry -q  {|op, path, new_path|
            if $op in ['Write'] {
                if $clear { ansi cls }
                do $transform (run-cmd $ctx)
                if not $clear { print $"(char newline)(ansi grey)------(ansi reset)(char newline)" }
            }
        }
    }
}
