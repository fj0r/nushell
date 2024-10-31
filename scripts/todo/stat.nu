use common.nu *

def 'precent' [] {
    ($in * 10000 | math round) / 100
}

def 'frequency' [-w: int] {
    let o = $in
    '' | fill -c '*' -w ($o * $w | math round)
}

def 'histogram-column' [column --len(-l):int = 50] {
    let o = $in
    let total = $o | get $column | math sum
    let max = $o | get $column | math max | ($in / $total)
    $o
    | each {|x|
        let c = $x | get $column | $in / $total
        $x
        | insert precent $"($c | precent)%"
        | insert frequency ($c / $max | frequency -w $len)
    }
}

def cmpl-interval [] {
    [hour day month year]
}

def cmpl-subject [] {
    [created updated]
}

export def todo-activities [
    subject?: string@cmpl-subject = 'updated'
    --limit(-l):int=21
    --interval(-i): string@cmpl-interval
] {
    let dfs = match $interval {
        'hour' => '%Y-%m-%d %H'
        'day' => '%Y-%m-%d'
        'month' => '%Y-%m'
        'year' => '%Y'
        _ => '%Y-%m-%d'
    }
    run $"
        select strftime\('($dfs)', ($subject)\) as date
        , count\(1\) as count
        from todo
        group by date
        order by date desc
        limit ($limit)
    "
    | reverse
    | histogram-column count
}
