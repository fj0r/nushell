use libs/db.nu *
use tag_base.nu *
use completion.nu *

# delete scratch in tag
export def scratch-tag-clean [
    ...tags: string@cmpl-tag-1
    --with-tag(-T)
] {
    let tags_id = $tags | tag-group | get or | each { scratch-tag-path-id ($in | split row ':') | last | get id } | str join ', '
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
    let from = $from | tag-group | get or.0
    let to = $to | tag-group | get or.0
    scratch-ensure-tags [$to]
    let q = $"with (tag-tree)
    update scratch_tag set tag_id = \(
        select id from tags where name = (Q $to)
    \) where scratch_id = ($id) and tag_id in \(
        select id from tags where name = (Q $from)
    \)"
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
        let tids = sqlx $"with (tag-tree) select tags.id from tags
            where name in \(($tags.not | each {Q $in} | str join ',')\)
        " | get id
        $tids | scratch-untagged $id
    }
}
