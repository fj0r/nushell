export def spy [tag?] {
    let o = $in
    let t = [
        $'(ansi xterm_grey)--------(ansi xterm_olive)($tag)(ansi xterm_grey)--------'
        $'(ansi xterm_grey39)($o | describe)'
        $'(ansi xterm_grey66)($o | to yaml)'
        (ansi reset)
    ]
    print -e ($t | str join (char newline))
    $o
}

export-env {
    $env.comma_log_level = 2
    $env.comma_log_file = ''
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
    if $lv < $env.comma_log_level {
        return
    }
    let ty = ['TRC' 'DBG' 'INF' 'WRN' 'ERR' 'CRT']
    let msg = parse_msg $args
    if ($env.comma_log_file? | is-empty) {
        let c = ['navy' 'teal' 'xgreen' 'xpurplea' 'olive' 'maroon']
        let gray = ansi light_gray
        let dark = ansi grey39
        let l = $"(ansi dark_gray)($ty | get $lv)"
        let t = $"(ansi ($c | get $lv))($msg.time)"
        let g = $msg.tag
        | transpose k v
        | each {|y| $"($dark)($y.k)=($gray)($y.v)"}
        | str join ' '
        | do { if ($in | is-empty) {''} else {$in} }
        let m = $"($gray)($msg.txt | str join ' ')"
        let r = [$t $l $g $m]
        | where { $in | is-not-empty }
        | str join $'($dark)│'
        print -e $r
    } else {
        [
            ''
            $'#($ty | get $lv)# ($msg.txt | str join " ")'
            ...($msg.tag | transpose k v | each {|y| $"($y.k)=($y.v | to nuon)"})
            ''
        ]
        | str join (char newline)
        | save -af ~/.cache/nonstdout
    }
}

export alias l0 = ll 0
export alias l1 = ll 1
export alias l2 = ll 2
export alias l3 = ll 3
export alias l4 = ll 4
export alias l5 = ll 5
export alias _TRC = ll 0
export alias _DBG = ll 1
export alias _INF = ll 2
export alias _WRN = ll 3
export alias _ERR = ll 4
export alias _CRT = ll 5

def "nu-complete ps" [] {
    ps -l | each {|x| { value: $"($x.pid)", description: $x.command } }
}

export def wait-pid [pid: string@"nu-complete ps"] {
    do -i { tail --pid $pid -f /dev/null }
}

export def wait-cmd [action -i: duration = 1sec  -t: string] {
    mut time = 0
    loop {
        l0 { time: $time } $t
        let c = do --ignore-errors $action | complete | get exit_code
        if ($c == 0) { break }
        sleep $i
        $time = $time + 1
    }
}

# perform or print
export def --wrapped pp [
    ...x
    --print(-p)
    --as-str
] {
    if $print or (do -i { $env.comma_index | get $env.comma_index.dry_run } | default false) {
        use lib/run.nu
        let r = run dry $x --strip
        if $as_str {
            $r
        } else {
            print -e $"(ansi light_gray)($r)(ansi reset)(char newline)"
        }
    } else {
        use lib/tree.nu spread
        ^$x.0 ...(spread ($x | range 1..))
    }
}

export def outdent [] {
    let txt = $in | lines | range 1..
    let indent = $txt.0 | parse --regex '^(?<indent>\s*)' | get indent.0 | str length
    $txt
    | each {|s| $s | str substring $indent.. }
    | str join (char newline)
}

export def batch [
    ...modules
    --bare (-b)
] {
    let o = $in
    let o = if ($o | describe -d).type == 'list' {
        $o
        | each {|x|
            if ($x | describe -d).type == 'list' {
                $x | str join ' '
            } else {
                $x
            }
        }
    } else {
        $o
        | lines
        | split row ';'
        | flatten
    }
    let modules = $modules
    | each { $'source ($in)' }
    let cmd = if $bare { [] } else {
        [
            'use comma/main.nu *'
            'use comma/utils.nu *'
        ]
    }
    | append [...$modules ...$o]
    | str join (char newline)
    print -e $"(ansi $env.comma_index.settings.theme.batch_hint)($cmd)(ansi reset)"
    let begin = date now
    nu -c $cmd
    let duration = (date now) - $begin
    print -e $"(ansi $env.comma_index.settings.theme.batch_hint)($duration)(ansi reset)"
}

export def deprecated [old new] {
    let o = (ansi yellow_bold)
    let n = (ansi light_green)
    let g = (ansi light_gray_italic)
    let r = (ansi reset)
    print -e $"($o)($old)($g) is deprecated, use ($r)($n)($new)($r)"
}
