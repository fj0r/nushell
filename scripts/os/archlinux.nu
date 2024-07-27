def 'nu-complete aur' [ctx] {
    let k = $ctx | split row ' ' | last | str trim
    if ($k | str length) < 2 {
        return
    }
    let d = paru -Ss $k | lines
    mut r = []
    mut cur = {}
    let char = {
        i : (ansi xterm_yellow)
        v : (ansi xterm_blue)
        c : (ansi xterm_grey)
        x : (ansi xterm_red)
        _ : (ansi reset)
        t : (char tab)

    }
    for i in 0..<($d | length) {
        if ($i mod 2) == 0 {
            $cur = ($d
                | get $i
                | parse -r '(?<t>.+?)/(?<n>.+?) (?<v>.+?) \[(?<c>.+?)\](?<x>.+)?'
                | first
                )
        } else {
            let t = $"($char.i)($cur.t)"
            let v = $"($char.v)($cur.v)"
            let c = $"($char.c)($cur.c)"
            let x = $cur.x
                | str replace -ra  '\] \[' '/'
                | str replace -ra  '[\[ \]]' ''
            let x = if ($x | is-empty) { "" } else { $"($char.c)/($x)" }
            let d = $"(char newline)($char.c)($d | get $i)"
           $r ++= {
                value: $cur.n
                description: $"($t)($x)($char.t)($v)($char.t)($c)($char._)"
           }
        }
    }
    $r
}

export def --wrapped pa [...args: string@"nu-complete aur"] {
    if ($args | is-empty) {
        paru -Syu
    } else if ($args | all { not ($in | str starts-with '-') }) {
        paru -S ...$args
    } else {
        paru ...$args
    }
}
