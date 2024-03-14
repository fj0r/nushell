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

export def --wrapped ll [lv ...args] {
    let c = ['navy' 'teal' 'xpurplea' 'xgreen' 'olive' 'maroon']
    let gray = (ansi light_gray)
    let dark = (ansi grey39)
    let t = date now | format date '%Y-%m-%dT%H:%M:%S'
    let t = $"(ansi ($c | get $lv))($t)"
    let s = $args
    | reduce -f {tag: {}, msg:[]} {|x, acc|
        if ($x | describe -d).type == 'record' {
            $acc | update tag ($acc.tag | merge $x)
        } else {
            $acc | update msg ($acc.msg | append $x)
        }
    }
    let g = $s.tag
    | transpose k v
    | each {|y| $"($dark)($y.k)=($gray)($y.v)"}
    | str join ' '
    | do { if ($in | is-empty) {''} else {$in} }
    let m = $"($gray)($s.msg | str join ' ')"
    let r = [$t $g $m]
    | where { $in | is-not-empty }
    | str join $'($dark)│'
    print -e $r
}

export alias l0 = ll 0
export alias l1 = ll 1
export alias l2 = ll 2
export alias l3 = ll 3
export alias l4 = ll 4
export alias l5 = ll 5

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
