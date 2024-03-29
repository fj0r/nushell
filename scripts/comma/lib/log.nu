def get_settings [] {
    {
        level: ($env.nlog_level? | default 2)
        file: ($env.nlog_file?)
    }
}

export-env {
    $env.nlog_prefix = ['TRC' 'DBG' 'INF' 'WRN' 'ERR' 'CRT']
    $env.nlog_prefix_index = {
        trc: 0
        dbg: 1
        inf: 2  msg: 2
        wrn: 3
        err: 4
        crt: 5
    }
}

def parse_msg [args] {
    let time = date now | format date '%Y-%m-%dT%H:%M:%S'
    let s = $args
        | reduce -f {tag: {}, txt:[]} {|x, acc|
            if ($x | describe -d).type == 'record' {
                $acc | update tag ($acc.tag | merge $x)
            } else {
                $acc | update txt ($acc.txt | append $x)
            }
        }
    {time: $time, txt: $s.txt, tag: $s.tag }
}

export def --wrapped ll [lv ...args] {
    let setting = get_settings
    if $lv < $setting.level {
        return
    }
    let msg = parse_msg $args
    if ($setting.file? | is-empty) {
        let c = ['navy' 'teal' 'xgreen' 'xpurplea' 'olive' 'maroon']
        let gray = ansi light_gray
        let dark = ansi grey39
        let l = $"(ansi dark_gray)($env.nlog_prefix | get $lv)"
        let t = $"(ansi ($c | get $lv))($msg.time)"
        let g = $msg.tag
        | transpose k v
        | each {|y| $"($dark)($y.k)=($gray)($y.v)"}
        | str join ' '
        let m = $msg.txt | str join ' '
        let m = if ($m | is-empty) { '' } else { $"($gray)($m)" }
        let r = [$t $l $g $m]
        | filter {|x| $x | is-not-empty }
        | str join $'($dark)│'
        print -e ($r + (ansi reset))
    } else {
        [
            ''
            $'#($env.nlog_prefix | get $lv)# ($msg.txt | str join " ")'
            ...($msg.tag | transpose k v | each {|y| $"($y.k)=($y.v | to json)"})
            ''
        ]
        | str join (char newline)
        | save -af $setting.file
    }
}

def 'nu-complete log-prefix' [] {
    $env.nlog_prefix_index | columns
}

export def --wrapped main [
    lv:string@'nu-complete log-prefix'
    ...args
] {
    ll ($env.nlog_prefix_index | get $lv) ...$args
}
