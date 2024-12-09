def cmpl-df-ex [] {
    [tmpfs overlay devtmpfs efivarfs]
}

export def dfx [-x:list<string>] {
    let d = if ($x | is-empty) {
        sudo df -h
        | lines
        | range 1..
        | filter { $in | str starts-with '/' }
    } else {
        let x = $x
        | each { $"--exclude-type=($in)" }
        sudo df -h ...$x
        | lines
        | range 1..
    }
    $d
    | parse -r '(?<fs>.+?)\s+(?<s>.+?)\s+(?<u>.+?)\s+(?<a>.+?)\s+.+?\s+(?<m>.+)'
    | each {|x|
        let u = $x.u | into filesize
        let a = $x.a | into filesize
        let s = $x.s | into filesize
        {
            filesystem: $x.fs
            size: $s
            used: $u
            availabe: $a
            radio: ($u / ($u + $a))
            mount: $x.m
        }
    }
}
