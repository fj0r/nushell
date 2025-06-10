def cmpl-ps [] {
    ps -l | each {|x|
        { value: $"($x.pid | fill -c ' ' -w 5) # ($x.name)", description: $x.command }
    }
}

export def wait-pid [pid: string@cmpl-ps] {
    do -i { tail --pid $pid -f /dev/null }
}

export def wait-cmd [action -i: duration = 1sec  -t: string='waiting'] {
    mut time = 0
    loop {
        print -e $"(ansi dark_gray)($t) (ansi dark_gray_italic)($i * $time)(ansi reset)"
        let c = do --ignore-errors $action | complete | get exit_code
        if ($c == 0) { break }
        sleep $i
        $time = $time + 1
    }
}

export def 'process ancestor' [pid: int@cmpl-ps] {
    let px = ps
    let cur = $px | where pid == $pid | get 0
    mut s = [$cur]
    loop {
        let ppid = $s | last | get ppid
        let p = $px | where pid == $ppid
        if ($p | is-empty) { break }
        $s ++= $p
    }
    $s
}

export def 'process descendant' [pid: int@cmpl-ps] {
    descendant (ps) $pid
}

def 'descendant' [ps pid] {
    let p = $ps | where ppid == $pid
    if ($p | is-empty) {
        return []
    } else {
        let pd = $p | each {|x| descendant $ps $x.pid } | flatten
        return [...$p ...$pd]
    }
}