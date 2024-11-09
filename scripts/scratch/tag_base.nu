use libs/db.nu *

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
