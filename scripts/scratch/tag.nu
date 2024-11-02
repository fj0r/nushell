# delete scratch in tag
export def scratch-tag-clean [
    ...tags: string@cmpl-tag
    --with-tag(-T)
] {
    let tags_id = sqlx $"with (tag-tree), tid as \(
        select id from tags where name in \(($tags | each {Q $in} | str join ', ')\)
    \), (tag-branch ids --where 'id in (select id from tid)')
    select id from ids"
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

# add tag
export def scratch-ensure-tags [...tags] {
    mut ids = []
    for tag in $tags {
        let ts = $tag | split row ':'
        mut pid = sqlx $"insert into tag \(parent_id, name\) values \(-1, (Q $ts.0)\)
            on conflict \(parent_id, name\) do update set parent_id = EXCLUDED.parent_id
            returning id, name;"
            | get 0.id
        for t in ($ts | range 1..) {
            $pid = sqlx $"insert into tag \(parent_id, name\) values
            \(($pid), (Q $t)\)
            on conflict \(parent_id, name\) do update set parent_id = EXCLUDED.parent_id
            returning id, name;"
            | get 0.id
        }
        $ids ++= $pid
    }
    return $ids
}

export def scratch-tag-rename [from:string@cmpl-tag-id to] {
    sqlx $"update tag set name = (Q $to) where id = ($from)"
}

export def scratch-tag-hidden [tag:int@cmpl-tag-id] {
    sqlx $"update tag set hidden = not hidden where id = ($tag) returning hidden"
}
