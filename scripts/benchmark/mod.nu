export def std [
    --count(-c): int = 5
    --total(-t): duration = 1sec
    action: closure
] {
    let begin = date now
    mut r = [$begin]
    loop {
        do $action
        let now = date now
        if ($now - $begin) > $total and ($r | length) > $count { break }
        # TODO: optimize
        $r ++= [$now]
    }
    let total = ($r | last) - $begin
    let times = ($r | length) - 1
    let average = $total / $times
    mut n = []
    for i in ..<(($r | length) - 1) {
        $n ++= [(($r | get ($i + 1)) - ($r | get $i) | into int | $in / 1000)]
    }
    {
        QPS: (1sec / $average)
        count: $times
        total: $total
        average: $average
        median: ($n | math median | into int | $in * 1000 | into duration)
        stddev: ($n | math stddev | into int | $in * 1000 | into duration)
    }
}

export def main [
    --count(-c): int = 5
    --total(-t): duration = 1sec
    action: closure
] {
    let begin = date now
    mut end = date now
    mut times = 0
    loop {
        do $action
        $end = date now
        $times += 1
        if ($end - $begin) > $total and $times >= $count { break }
    }
    let total = $end - $begin
    let average = $total / $times
    {
        QPS: (1sec / $average)
        count: $times
        total: $total
        average: $average
    }
}
