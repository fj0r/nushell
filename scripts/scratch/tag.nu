use libs/db.nu *
use tag_base.nu *
use completion.nu *

# delete scratch in tag
export def scratch-tag-clean [
    ...tags: string@cmpl-tag-1
    --with-tag(-T)
] {
    let tags_id = $tags | tag-group | get or
    | scratch-tag-paths-id ...($in | each {|x| $x | split row ':' })
    | each { $in.data | last | get id }
    | str join ', '
    let tags_id = sqlx $"with recursive g as \(
        select id, parent_id from tag where id in \(($tags_id)\)
        union all
        select t.id, t.parent_id from tag as t join g on g.id = t.parent_id
    \) select id from g"
    | get id | each { $in | into string } | str join ', '
    let id = sqlx $"delete from scratch where id in \(
        select scratch_id from scratch_tag where tag_id in \(($tags_id)\)
        \) returning id" | get id
    let tid = sqlx $"delete from scratch_tag where scratch_id in \(($id | str join ', ')\)
        returning scratch_id, tag_id"
    let tags = if $with_tag {
        sqlx $"delete from tag where id in \(($tags_id)\)"
        $tags_id
    }
    {
        scratch: $id
        scratch_tags: $tid
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
    let tag = $from | tag-group | get or | scratch-ensure-tags $in | get 0
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
    let fr = $from | tag-group | get or.0 | split row ':'
    let fo = scratch-tag-paths-id $fr | get data.0
    let fo = if ($fr | length) == ($fo | length) { $fo | last | get id }
    if ($fo | is-empty) { error make {msg: $"`tag ($from)` not exists" }}
    let to = $to | tag-group | get or.0
    let to = scratch-ensure-tags [$to] | last
    let q = $"update scratch_tag set tag_id = ($to) where scratch_id = ($id) and tag_id = ($fo)"
    sqlx $q
}

export def scratch-tag-toggle [
    id: int@cmpl-scratch-id
    ...tags: string@cmpl-tag-2
] {
    let tags = $tags | tag-group
    if ($tags.and | is-not-empty) {
        let tids = scratch-ensure-tags $tags.and
        $tids | scratch-tagged $id
    }
    if ($tags.not | is-not-empty) {
        $tags.not | each {
            let o = $in | split row ':'
            let i = scratch-tag-paths-id $o | get data.0
            if ($o | length) == ($i | length) {
                $i | last | get id
            }
        } | scratch-untagged $id
    }
}

export def scratch-tag-add [
    ...tags: string@cmpl-tag-1
] {
    $tags | tag-group | get or | scratch-ensure-tags $in
}

export def scratch-tag-delete [
    ...tags: string@cmpl-tag-1
] {
    # TODO:
}
