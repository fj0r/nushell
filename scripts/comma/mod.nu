export use utils.nu *
use lib/resolve.nu

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

          source ,.nu
          "
        }
    ]
}

def gendict [size extend] {
    let keys = $in
    mut k = []
    let n = $keys | length
    let rk = random chars -l ($n * $size)
    for i in 1..$n {
        let b = ($i - 1) * $size
        let e = $i * $size
        $k ++= ($rk | str substring $b..$e)
    }
    let ids = $keys
    | zip $k
    | reduce -f {} {|x, acc|
        let id = if ($x.0 | describe -d).type == 'list' { $x.0 } else { [$x.0] }
        $id | reduce -f $acc {|i,a| $a | insert $i $"($id.0)_($x.1)" }
    }
    $extend
    | transpose k v
    | reduce -f $ids {|x, acc|
        $acc | insert $x.k { $x.v }
    }
}

export-env {
    use lib/os.nu
    use utils.nu
    # batch mode
    if ($env.config? | is-not-empty) {
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
    $env.comma = {}
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
            wd: $env.PWD
            session_id: (random chars)
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
                    if ($x.report | is-not-empty) {
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
            distro: (os distro)
            test: {|dsc, spec|
                use lib/test.nu
                let fmt = $env.comma_index.settings.test_message
                test $fmt 0 $dsc $spec
            }
            spy: { $in | utils spy }
            tips: {|...m|
                if ($m | length) > 2 {
                    print -e $"(ansi light_gray_italic)Accepts no more than (ansi yellow_bold)2(ansi reset)(ansi light_gray_italic) parameters(ansi reset)"
                } else {
                    print -e $"(ansi light_gray_italic)($m.0)(ansi reset) (ansi yellow_bold)($m.1?)(ansi reset)"
                }
            }
            T: {|f| {|r,a,s| do $f $r $a $s; true } }
            F: {|f| {|r,a,s| do $f $r $a $s; false } }
            I: {|x| $x }
            diff: {|x|
                use lib/test.nu
                test diffo {expect: $x.expect, result: $x.result}
            }
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
    | str substring 0..<$context.1
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

def completion [...context] {
    use lib/run.nu
    $context
    | parse argv
    | run complete (resolve comma)
}

use lib/reg.nu

export def --env 'comma dir' [opts] {
    reg node $in $opts
}

export def --env 'comma fun' [action opts?] {
    reg action $in $action $opts
}

export def --env 'comma val' [type val] {
    reg scope $in $type $val
}

export def 'comma template' [] {
    let tmpl_dir = [$nu.default-config-dir 'scripts' 'comma' 'tmpl'] | path join
    let tmpl = ls $"($tmpl_dir)" | get name | path relative-to $tmpl_dir | sort-by name
    let txs = $tmpl
    | parse -r '\d+_(?<n>\w+)'
    | get n
    | str replace --all '_' ' '
    | input list -i -m 'create `,.nu` from'
    let seg = $txs | each {|x| $tmpl | get $x }
    | inspect
    let time = date now | format date '%Y-%m-%d{%w}%H:%M:%S'
    let nl = char newline
    let obj = [$env.PWD, ',.nu'] | path join
    if ($obj | path exists) {
        $seg
    } else {
        [base.nu, ...$seg]
    }
    | each {|x|
        [$tmpl_dir, $x]
        | path join
        | open $in
        | str replace '{{time}}' $time
        | str trim -c $nl
        | do { [$"### {{{ ($x)", $in , $"### }}}($nl)"] | str join $nl }
    }
    | save -af $obj
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
    --expose (-x) # for test
    --edit (-e)
    --format: string = tree # tree | table | markdown
    --all (-a) # show hide
    --template
    --readme
    ...args:string@'completion'
] {
    if $completion {
        use lib/run.nu
        let c = $args | flatten | run complete (resolve comma)
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
        $args | flatten | test run (resolve comma) --opt {watch: $watch}
    } else if $expose {
        expose $args.0 ($args | range 1..) (resolve comma)
    } else if $vscode {
        use lib/vscode-tasks.nu
        vscode-tasks merge $args (resolve comma) --opt {json: $json}
    } else if $readme {
        cat ([$nu.default-config-dir 'scripts' 'comma' 'README.md'] | path join)
    } else if $edit {
        ^$env.EDITOR ,.nu
    } else if $template {
        comma template
    } else if ($args | is-empty) {
        if ([$env.PWD, ',.nu'] | path join | path exists) {
            use lib/info.nu
            info (resolve comma) {all: $all, format: $format}
        } else {
            comma template
        }
    } else {
        if $print {
            $env.comma_index = ($env.comma_index | upsert $env.comma_index.dry_run true)
        }
        use lib/run.nu
        $args | flatten | run (resolve comma) --opt {watch: $watch, print: $print} --info-opt {all: $all, format: tree}
    }
}
