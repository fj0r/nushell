def cmpl-tags [...prefix] {
    sqlx $"with (tag-tree) select * from tags"
    | get name
    | filter { $in | is-not-empty }
    | each {|x| $prefix | each {|y| $"($y)($x)" } }
    | flatten
}

def id-tag [] {
    let id = $in
    sqlx $"with (tag-tree) select * from tags
        join scratch_tag on tags.id = scratch_tag.tag_id
        where scratch_tag.scratch_id = ($id)
    " | get name | each { $":($in)" }
}

export def cmpl-tag-1 [] {
    cmpl-tags ':'
}

export def cmpl-tag-2 [] {
    cmpl-tags '+' '^'
}

export def cmpl-tag-3 [] {
    cmpl-tags ':' '+' '^'
}

export def cmpl-tag-id [] {
   sqlx $"with (tag-tree) select * from tags" | each { $"($in.id) # ($in.name)" }
}

export def cmpl-id-tag [ctx] {
    if (scope commands | where name == 'argx parse' | is-empty) {
        cmpl-tags ':'
    } else {
        $ctx | argx parse | get -i pos.id | id-tag
    }
}

export def tag-group [] {
    let x = $in
    mut $r = { not: [], and: [], or: [], other: [] }
    for i in $x {
        match ($i | str substring ..<1) {
            '^' => { $r.not ++= $i | str substring 1.. }
            '+' => { $r.and ++= $i | str substring 1.. }
            ':' => { $r.or ++= $i | str substring 1.. }
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

export def scratch-tag-path-id [tag_path: list<string>] {
    let ts = $tag_path | each { $"\((Q $in)\)" } | str join ', '
    sqlx $"with recursive input\(name\) as \(
            values ($ts)
        \), v as \(
            select row_number\(\) over \(\) as lv, name from input
        \), g as \(
            select 1 as lv, parent_id, id, tag.name from tag
            join v on lv = v.lv
            where v.lv = 1 and tag.name = v.name
            union all
            select g.lv + 1 as lv, t.parent_id, t.id, t.name from tag as t
            join v on \(g.lv + 1\) = v.lv
            join g on g.id = t.parent_id
            where t.name = v.name
        \) select * from g;"
}

# add tag
export def scratch-ensure-tags [tags] {
    mut ids = []
    for tag in $tags {
        let ts = $tag | split row ':'
        let r = scratch-tag-path-id $ts

        mut idx = 0
        mut pid = -1
        mut name = null
        for i in $ts {
            let x = $r | where parent_id == $pid and name == $i
            if ($x | is-empty) {
                $name = $i
                break
            } else {
                $pid = $x.0.id
            }
            $idx += 1
        }

        if ($name != null) {
            for t in ($ts | range $idx..) {
                $pid = sqlx $"insert into tag \(parent_id, name\) values
                \(($pid), (Q $t)\)
                on conflict \(parent_id, name\) do update set parent_id = EXCLUDED.parent_id
                returning id, name;"
                | get 0.id
                print $"(ansi grey)Tag has been created: (ansi yellow)($t)(ansi reset)"
            }
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

