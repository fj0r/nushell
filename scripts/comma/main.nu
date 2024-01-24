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

export def --wrapped ll [...args] {
    let c = ['navy' 'teal' 'xpurplea' 'xgreen' 'olive' 'maroon']
    let t = date now | format date '%Y-%m-%dT%H:%M:%S'
    let n = $args | length
    let lv = if $n == 1 { 0 } else { $args.0 }
    let s = match $n {
        1 => ($args | range 0..)
        _ => ($args | range 1..)
    }
    let s = $s
    | reduce -f {tag: {}, msg:[]} {|x, acc|
        if ($x | describe -d).type == 'record' {
            $acc | update tag ($acc.tag | merge $x)
        } else {
            $acc | update msg ($acc.msg | append $x)
        }
    }
    let gray = (ansi light_gray)
    let dark = (ansi grey39)
    let g = $s.tag
    | transpose k v
    | each {|y| $"($dark)($y.k):($gray)($y.v)"}
    | str join ' '
    | do { if ($in | is-empty) {''} else {$"($in)($dark)|"} }
    let r = [
        $"(ansi ($c | get $lv))($t)($dark)|($g)"
        $"($gray)($s.msg | str join ' ')(ansi reset)"
    ]
    | where { not ($in | is-empty) }
    | str join ' '
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

def 'find parent' [] {
    let o = $in
    let depth = ($env.PWD | path expand | path split | length) - 1
    mut cur = [',.nu']
    mut e = ''
    for i in 0..$depth {
        $e = ($cur | path join)
        if ($e | path exists) { break }
        $cur = ['..', ...$cur]
        $e = ''
    }
    $e
}



def 'comma file' [] {
    [
        {
          condition: {|_, after| $after | path join ',.nu' | path exists}
          code: "
          print -e $'(ansi default_underline)(ansi default_bold),(ansi reset).nu (ansi green_italic)detected(ansi reset)...'
          print -e $'(ansi $env.comma_index.settings.theme.info)activating(ansi reset) (ansi default_underline)(ansi default_bold),(ansi reset) module with `(ansi default_dimmed)(ansi default_italic)source ,.nu(ansi reset)`'

          # TODO: allow parent dir
          $env.comma_index.wd = $after
          $env.comma_index.session_id = (random chars)

          source ,.nu
          "
        }
    ]
}

export-env {
    use lib/utils.nu *
    # batch mode
    if not ($env.config? | is-empty) {
        $env.config = ( $env.config | upsert hooks.env_change.PWD { |config|
            let o = ($config | get -i hooks.env_change.PWD)
            let val = (comma file)
            if $o == null {
                $val
            } else {
                $o | append $val
            }
        })
    }
    $env.comma_index = (
        [
            [children sub s]
            [description desc dsc d]
            [action act a]
            [completion cmp c]
            [filter flt f]
            [computed cpu u]
            [watch wth w]
            tag
            # test
            [expect exp e x]
            [mock test_args m]
            [report rpt r]
            # internal
            dry_run
        ]
        | gendict 5 {
            settings: {
                test_group: {|x|
                    let indent = '' | fill -c '  ' -w $x.indent
                    let s = $"(ansi bg_dark_gray)GROUP(ansi reset)"
                    let t = $"(ansi yellow_bold)($x.title)(ansi reset)"
                    let d = $"(ansi light_gray)($x.desc)(ansi reset)"
                    print $"($indent)($s) ($t) ($d)"
                }
                test_message: {|x|
                    let indent = '' | fill -c '  ' -w $x.indent
                    let status = if $x.status {
                        $"(ansi bg_green)SUCC(ansi reset)"
                    } else {
                        $"(ansi bg_red)FAIL(ansi reset)"
                    }
                    print $"($indent)($status) (ansi yellow_bold)($x.message) (ansi light_gray)($x.args)(ansi reset)"
                    if not ($x.report | is-empty) {
                        let report = if $indent == 0 {
                            $x.report
                        } else {
                            $x.report | each {|i| $"($indent)($i)"}
                        }
                        | str join (char newline)
                        print $"(ansi light_gray)($report)(ansi reset)"
                    }
                }
                theme: {
                    info: 'yellow_italic'
                    batch_hint: 'dark_gray'
                    watch_separator: {
                        let w = term size | get columns
                        print -e $"(ansi dark_gray)('' | fill -c '-' -w $w)(ansi reset)"
                    }
                }
            }
            distro: (distro)
            batch: {|mod|
                let o = $in
                    | lines
                    | split row ';'
                    | flatten
                let cmd = ['use comma/main.nu *' $'source ($mod)' ...$o ]
                    | str join (char newline)
                print -e $"(ansi $env.comma_index.settings.theme.batch_hint)($cmd)(ansi reset)"
                nu -c $cmd
            }
            test: {|dsc, spec|
                use lib/test.nu
                let fmt = $env.comma_index.settings.test_message
                test $fmt 0 $dsc $spec
            }
            spy: {$in | spy }
            tips: {|...m|
                if ($m | length) > 2 {
                    print -e $"(ansi light_gray_italic)Accepts no more than (ansi yellow_bold)2(ansi reset)(ansi light_gray_italic) parameters(ansi reset)"
                } else {
                    print -e $"(ansi light_gray_italic)($m.0)(ansi reset) (ansi yellow_bold)($m.1?)(ansi reset)"
                }
            }
            log: {|...args|
                ll ...$args
            }
            T: {|f| {|r,a,s| do $f $r $a $s; true } }
            F: {|f| {|r,a,s| do $f $r $a $s; false } }
            I: {|x| $x }
            diff: {|x|
                use lib/test.nu
                test diffo {expect: $x.expect, result: $x.result}
            }
            outdent: { $in | outdent }
            config: {|cb|
                # FIXME: no affected $env
                $env.comma_index.settings = (do $cb $env.comma_index.settings)
            }
        }
    )
}


def summary [$tbl] {
    let argv = $in
    use lib/tree.nu
    $argv
    | flatten
    | tree select --strict $tbl
    | $in.node
    | get $env.comma_index.sub
    | tree map { |pth, g, node| {
        path: $pth
        node: $node
    } }
}

def 'parse argv' [] {
    let context = $in
    $context.0
    | str substring 0..$context.1
    | split row ';'
    | last
    | str trim -l
    | split row -r '\s+'
    | range 1..
    | where not ($it | str starts-with '-')
}

def expose [t, a, tbl] {
    match $t {
        test => {
            use lib/test.nu
            $a | test run $tbl
        }
        summary => {
            $a | summary $tbl
        }
        vscode => {
            use lib/vscode-tasks.nu
            $a | vscode-tasks gen $tbl
        }
        dry => {
            use lib/run.nu
            run dry $a
        }
        _ => {
            let _ = $env.comma_index
            do $_.tips "expose has different arguments" [
                test
                summary
                vscode
            ]
        }
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

def completion [...context] {
    use lib/resolve.nu
    use lib/run.nu
    $context
    | parse argv
    | run complete (resolve comma)
}

export def --wrapped , [
    # flag with parameters is not supported
    --json (-j)
    --completion (-c)
    --vscode
    --test (-t)
    --tag (-g)
    --watch (-w)
    --print (-p)
    --expose (-e) # for test
    --readme
    ...args:string@'completion'
] {
    use lib/resolve.nu
    if ($args | is-empty) {
        if $vscode {
            use lib/vscode-tasks.nu
            vscode-tasks merge $args (resolve comma) --opt {json: $json}
        } else if $readme {
            ^$env.EDITOR ([$nu.default-config-dir 'scripts' 'comma.md'] | path join)
        } else if ([$env.PWD, ',.nu'] | path join | path exists) {
            ^$env.EDITOR ,.nu
        } else {
            let a = [yes no] | input list 'create ,.nu ?'
            let time = date now | format date '%Y-%m-%d{%w}%H:%M:%S'
            let txt = [($nu.config-path | path dirname) scripts comma_tmpl.nu]
                | path join
                | open $in
                | str replace '{{time}}' $time
            if $a == 'yes' {
                $txt | save $",.nu"
                #source ',.nu'
            } else {
                $txt
            }
        }
    } else {
        let tbl = resolve comma
        if $completion {
            use lib/run.nu
            let c = $args | flatten | run complete $tbl
            if $vscode {
                $c
                | each {|x|
                    if ($x | describe -d).type == 'string' { $x } else {
                        $"($x.value)||($x.description)|"
                    }
                }
                | str join (char newline)
            } else if $json {
                $c | to json
            } else {
                $c
            }
        } else if $test {
            use lib/test.nu
            $args | flatten | test run $tbl --opt {watch: $watch}
        } else if $expose {
            expose $args.0 ($args | range 1..) $tbl
        } else {
            if $print {
                $env.comma_index = ($env.comma_index | upsert $env.comma_index.dry_run true)
            }
            use lib/run.nu
            $args | flatten | run $tbl --opt {watch: $watch}
        }
    }
}
