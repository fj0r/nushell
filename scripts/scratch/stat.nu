use common.nu *
use libs/db.nu *
use libs/histogram.nu *


def cmpl-interval [] {
    [hour day month year]
}

def cmpl-subject [] {
    [created updated]
}

export def scratch-activities [
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
        from scratch
        group by date
        order by date desc
        limit ($limit)
    "
    | reverse
    | histogram-column count
}
