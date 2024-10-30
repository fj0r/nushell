export def run [stmt] {
    open $env.TODO_DB | query db $stmt
}

export def fmt-date [] {
    $in | format date '%FT%H:%M:%S'
}

def variants-edit [file? --line:int] {
    if ($line | is-empty) {
        ^$env.EDITOR $file
    } else {
        if ($env.EDITOR | find vim | is-not-empty) {
            ^$env.EDITOR $"+($line)" $file
        } else {
            ^$env.EDITOR $file
        }
    }
}

export def block-edit [temp --line:int] {
    let content = $in
    let tf = mktemp -t $temp
    $content | save -f $tf
    variants-edit $tf --line $line
    let c = open $tf --raw
    rm -f $tf
    $c
}

export def Q [...t] {
    let s = $t | str join '' | str replace -a "'" "''"
    $"'($s)'"
}

export def tag-group [] {
    let x = $in
    mut $r = { not: [], and: [], normal: [] }
    for i in $x {
        match ($i | str substring ..<1) {
            '!' => { $r.not ++= $i | str substring 1.. }
            '&' => { $r.and ++= $i | str substring 1.. }
            _ => { $r.normal ++= $i}
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

export def dbg [switch content -t:string] {
    if $switch {
        print $"(ansi grey)($t)│($content)(ansi reset)"
    }
}

export def 'str plain' [] {
    $in | str replace -ra '\e\[.*?m' ''
}

export def 'filter-empty' [] {
    $in
    | transpose k v
    | reduce -f {} {|i,a|
        if ($i.v | is-empty) {
            $a
        } else {
            $a | insert $i.k $i.v
        }
    }
}
