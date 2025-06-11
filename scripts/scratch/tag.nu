use libs/db.nu *
use tag_base.nu *
use completion.nu *

# delete scratch in tag
export def scratch-tag-clean [
    tags: string@cmpl-tag-1
    --with-tag(-T)
] {
    let tags_id = $tags | tags-group | get or
    | scratch-tag-paths-id ...$in
    | each { $in.data | last | get id }
    | scratch-tags-children ...$in
    | each { $in | into string } | str join ', '
    let $scratch = sqlx $"select scratch_id from scratch_tag where tag_id in \(($tags_id)\)"
    | get scratch_id
    let sid = $scratch | each { $in | into string } | str join ', '
    sqlx $"delete from scratch_tag where scratch_id in \(($sid)\) and tag_id in \(($tags_id)\)"

    let other_tag = sqlx $"select scratch_id, count\(1\) as c from scratch_tag where scratch_id in \(($sid)\) group by scratch_id having c > 0" | get scratch_id
    let scratch = $scratch | where {|x| $x not-in $other_tag }
    for i in $scratch {
        sqlx $"delete from scratch where id in \(($i)\)"
    }
    let tags = if $with_tag {
        sqlx $"delete from tag where id in \(($tags_id)\)"
        $tags_id
    }
    {
        scratch: $scratch
        tags: $tags
    }
}

export def scratch-tagged [id] {
    let tids = $in | each { $"\(($in)\)"} | str join ', '
    let q = $"with x\(tag_id\) as \(VALUES ($tids)\)
        insert into scratch_tag select ($id) as scratch_id, x.tag_id from x where 1
        on conflict \(scratch_id, tag_id\) do nothing returning tag_id"
    sqlx $q
}

export def scratch-untagged [id] {
    let tids = $in | into string | str join ', '
    sqlx $"delete from scratch_tag where scratch_id = ($id) and tag_id in \(($tids)\)"
}

export def scratch-tag-rename [from:string@cmpl-tag-1 to] {
    let tag = $from | tags-group | get or | scratch-ensure-tags $in | get 0
    sqlx $"update tag set name = (Q $to) where id = ($tag)"
}

export def scratch-tag-hidden [tag:int@cmpl-tag-id] {
    sqlx $"update tag set hidden = not hidden where id = ($tag) returning hidden"
}

export def scratch-tag-move [
    id: int@cmpl-scratch-id
    --from(-f):string@cmpl-id-tag
    --to(-t):string@cmpl-tag-1
] {
    let f = $from | tags-group | get or.0 | scratch-tag-paths-id $in | first
    if not $f.present { error make {msg: $"`tag ($from)` not exists" }}
    let f = if $f.present { $f.data | last | get id }
    let to = $to | tags-group | get or.0
    let to = scratch-ensure-tags [$to] | last
    let q = $"update scratch_tag set tag_id = ($to) where scratch_id = ($id) and tag_id = ($f)"
    sqlx $q
}

export def scratch-move-tag [
    from:string@cmpl-tag-1
    to:string@cmpl-tag-1
] {
    let f = $from | tags-group | get or.0 | scratch-tag-paths-id $in | first
    if not $f.present { error make {msg: $"`tag ($from)` not exists" } }
    let f = $f.data | last | get id
    let t = $to | tags-group | get or.0 | scratch-tag-paths-id $in | first
    if not $t.present { error make {msg: $"`tag ($to)` not exists" }}
    let t = $t.data | last | get id
    let q = $"update tag set parent_id = ($t) where id = ($f)"
    sqlx $q
}

export def scratch-tag-toggle [
    id: int@cmpl-scratch-id
    ...tags: string@cmpl-tag-2
] {
    let tags = $tags | tags-group
    if ($tags.and | is-not-empty) {
        let tids = scratch-ensure-tags $tags.and
        $tids | scratch-tagged $id
    }
    if ($tags.not | is-not-empty) {
        $tags.not | each {|o|
            let i = scratch-tag-paths-id $o | first
            if $i.present {
                $i.data | last | get id
            }
        } | scratch-untagged $id
    }
}

export def scratch-tag-add [
    ...tags: string@cmpl-tag-1
] {
    $tags | tags-group | get or | scratch-ensure-tags $in
}

export def scratch-tag-delete [
    ...tags: string@cmpl-tag-1
] {
    # TODO:
}
