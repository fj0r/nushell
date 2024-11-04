export def cmpl-tag [] {
    sqlx $"with (tag-tree) select * from tags" | get name | filter { $in | is-not-empty }
}

export def cmpl-atag [] {
    cmpl-tag | each {|x| $":($x)" }
}

export def cmpl-xtag [] {
    cmpl-tag | each {|x| [$":($x)" $"&($x)" $"^($x)"]} | flatten
}

export def cmpl-tag-id [] {
   sqlx $"with (tag-tree) select * from tags" | each { $"($in.id) # ($in.name)" }
}

export def tag-group [] {
    let x = $in
    mut $r = { not: [], and: [], normal: [], other: [] }
    for i in $x {
        match ($i | str substring ..<1) {
            '^' => { $r.not ++= $i | str substring 1.. }
            '&' => { $r.and ++= $i | str substring 1.. }
            ':' => { $r.normal ++= $i | str substring 1.. }
            _ => { $r.other ++= $i }
        }
    }
    $r
}

export def tag-branch [table: string, --where: string] {
    let n = $"($table)_(random chars -l 3)"
    $"($table) as \(
        select id, parent_id, hidden, name from tag where ($where)
        union all
        select ($n).id, ($n).parent_id, ($n).hidden, ($table).name || ':' || ($n).name as name from tag as ($n)
        join ($table) on ($n).parent_id = ($table).id
    \)"
}

export def tag-tree [name?: string='tags' --where: string='parent_id in (-1)'] {
    let n = $"_(random chars -l 3)"
    let b = tag-branch $n --where $where
    $"recursive ($b), ($n)_1 as \(
        select id, parent_id, hidden, name from ($n) order by length\(name\) desc
    \), ($name) as \(
        select id, hidden, name from ($n)_1 group by id
    \)"
}

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
export def scratch-ensure-tags [tags] {
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

export def scratch-tag-rename [from:string@cmpl-tag-id to] {
    sqlx $"update tag set name = (Q $to) where id = ($from)"
}

export def scratch-tag-hidden [tag:int@cmpl-tag-id] {
    sqlx $"update tag set hidden = not hidden where id = ($tag) returning hidden"
}

export def scratch-tag-move [
    id: int@cmpl-scratch-id
    --from(-f):string@cmpl-tag
    --to(-t):string@cmpl-tag
] {
    sqlx $"with (tag-tree)
    update scratch_tag set tag_id = \(
        select id from tags where name = (Q $to)
    \) where scratch_id = ($id) and tag_id = \(
        select id from tags where name = (Q $from)
    \)"
}

export def scratch-tag-toggle [
    id: int@cmpl-scratch-id
    ...tags: string@cmpl-xtag
] {
    let tags = $tags | tag-group
    let tids = scratch-ensure-tags $tags.normal
    $tids | scratch-tagged $id
    if ($tags.not | is-not-empty) {
        let tids = sqlx $"with (tag-tree) select tags.id from tags
            where name in \(($tags.not | each {Q $in} | str join ',')\)
        " | get id
        $tids | scratch-untagged $id
    }
}

