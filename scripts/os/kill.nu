def cmpl-pid [] {
    ps -l | each {|x|
        { value: $"($x.pid | fill -c ' ' -w 5) # ($x.name)", description: $x.command }
    }
}

export extern main [
    --force(-f)
    --quiet(-q)
    --signal(-s): int
    ...pid: int@cmpl-pid
]