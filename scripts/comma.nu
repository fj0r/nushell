module utils {
    export def gendict [size extend] {
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

    export def lg [tag?] {
        let o = $in
        print $'---($tag)---($o | describe)(char newline)($o | to yaml)'
        $o
    }

    export def 'str repeat' [n] {
        let o = $in
        if $n < 1 { return '' }
        mut r = ''
        for i in 0..($n - 1) {
            $r += $o
        }
        $r
    }

    export def unindent [] {
        let txt = $in | lines | range 1..
        let indent = $txt.0 | parse --regex '^(?P<indent>\s*)' | get indent.0 | str length
        $txt
        | each {|s| $s | str substring $indent.. }
        | str join (char newline)
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

def 'run exp' [expect result o] {
    let r = do $expect $result $o.args? $o.scope?
    if ($r | describe -d).type == 'bool' { $r } else {
        error make -u {msg: $"(view source $o.expect) must be bool" }
    }
}

def diffo [x] {
    let tbl = $x
    | transpose k v
    | if ($in | length) != 2 {
        error make -u { msg: "must be two fields" }
    } else {
        $in
    }
    | each {|i|
        let n = mktemp -t
        echo ($i.v? | default '' | into string) out> $n
        $i | insert n $n
    }
    let a = $tbl.0
    let b = $tbl.1
    let d = ^diff -u --color $a.n $b.n
    | lines
    | each {|x|
        if ($x | str starts-with $"--- ($a.n)") {
            $"--- ($a.k)"
        } else if ($x | str starts-with $"+++ ($b.n)") {
            $"+++ ($b.k)"
        } else {
            $x
        }
    }
    rm -f $a.n
    rm -f $b.n
    $d
}

def test [fmt, indent, dsc, o] {
    let result = do $o.spec? $o.args? $o.scope? | default false
    let exp_type = ($o.expect? | describe -d).type
    mut stat_list = []
    let status = if $exp_type == 'nothing' {
        true == $result
    } else if $exp_type == 'closure' {
        run exp $o.expect $result $o
    } else if $exp_type == 'list' {
        $stat_list = ($o.expect | each {|r| run exp $r $result $o })
        $stat_list | all {|x| $x == true }
    } else if $exp_type == 'record' {
    } else {
        $o.expect? == $result
    }
    let report = if $status { null } else {
        let e = if $exp_type == 'closure' {
            $"<(view source $o.expect)>"
        } else if $exp_type == 'list' {
            $o.expect | zip $stat_list
            | reduce -f [] {|i,a| $a | append (if $i.1 {'SUCC'} else {$"<(view source $i.0)>"}) }
        } else {
            $o.expect?
        }
        let r = {
            args: $o.args?
            result: $result
            expect: $e
        }
        if ($o.report? | is-empty) {
            $r | to yaml | lines
        } else {
            do $o.report $r
        }
    }
    do $fmt {
        indent: $indent
        status: $status
        message: $dsc
        args: $o.args?
        report: $report
    }
}

def 'comma file' [] {
    [
        {
          condition: {|_, after| not ($after | path join ',.nu' | path exists)}
          code: "$env.comma = null"
        }
        {
          condition: {|_, after| $after | path join ',.nu' | path exists}
          code: "
          print $'(ansi default_underline)(ansi default_bold),(ansi reset).nu (ansi green_italic)detected(ansi reset)...'
          print $'(ansi $env.comma_index.settings.theme.info)activating(ansi reset) (ansi default_underline)(ansi default_bold),(ansi reset) module with `(ansi default_dimmed)(ansi default_italic)source ,.nu(ansi reset)`'

          # TODO: allow parent dir
          $env.comma_index.wd = $after
          $env.comma_index.session_id = (random chars)

          source ,.nu
          "
        }
    ]
}

export-env {
    use utils *
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
                    let indent = '  ' | str repeat $x.indent
                    let s = $"(ansi bg_dark_gray)GROUP(ansi reset)"
                    let t = $"(ansi yellow_bold)($x.title)(ansi reset)"
                    let d = $"(ansi light_gray)($x.desc)(ansi reset)"
                    print $"($indent)($s) ($t) ($d)"
                }
                test_message: {|x|
                    let indent = '  ' | str repeat $x.indent
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
                tips: {|m, a|
                    print $"(ansi light_gray_italic)($m)(ansi reset) (ansi yellow_bold)($a)(ansi reset)"
                }
                theme: {
                    info: 'yellow_italic'
                    batch_hint: 'dark_gray'
                    watch_separator: $"(ansi dark_gray)------------------------------(ansi reset)"
                }
            }
            os: (os type)
            arch: (uname -m)
            lg: {$in | lg}
            batch: {|mod|
                let o = $in
                    | lines
                    | split row ';'
                    | flatten
                    | each {|x| $", ($x | str trim)" }
                let cmd = ['use comma.nu *' $'source ($mod)' ...$o ]
                    | str join (char newline)
                print $"(ansi $env.comma_index.settings.theme.batch_hint)($cmd)(ansi reset)"
                nu -c $cmd
            }
            test: {|dsc, spec|
                let fmt = $env.comma_index.settings.test_message
                test $fmt 0 $dsc $spec
            }
            T: { true }
            F: { false }
            I: {|x| $x }
            diff: {|x|
                diffo {expect: $x.expect, result: $x.result}
            }
            config: {|cb|
                # FIXME: no affected $env
                $env.comma_index.settings = (do $cb $env.comma_index.settings)
            }
        }
    )
}

def 'resolve node' [] {
    let o = $in
    let _ = $env.comma_index
    let t = ($o | describe -d).type
    if $t == 'closure' {
        { end: true,  $_.act: $o }
    } else if ($_.act in $o) {
        { end: true,  ...$o }
    } else if ($_.sub in $o) {
        { end: false, ...$o }
    } else {
        { end: false, $_.sub: $o}
    }
}

def 'tree op' [cur _] {
    mut op = $in
    mut wth = ($op.watch? | default [])
    mut flt = ($op.filter? | default [])
    if $_.flt in $cur { $flt ++= ($cur | get $_.flt) }
    if $_.wth in $cur { $wth ++= ($cur | get $_.wth) }
    {
        filter: $flt
        watch: $wth
    }
}

def 'tree select' [tree --strict] {
    let ph = $in
    let _ = $env.comma_index
    mut cur = $tree | resolve node
    mut op = {} | tree op $cur $_
    mut rest = []
    for i in $ph {
        if $cur.end {
            $rest ++= $i
        } else {
            $op = ($op | tree op $cur $_)
            let sub = $cur | get $_.sub
            if $i in $sub {
                $cur = ($sub | get $i | resolve node)
            } else {
                if $strict {
                    $cur = ({ do $_.settings.tips "not found" $i } | resolve node)
                } else {
                    $cur
                }
                break
            }
        }
    }
    {
        node: $cur
        rest: $rest
        ...$op
    }
}

def 'test suit' [] {
    let specs = $in
    mut lv = []
    for i in $specs {
        let l = $lv | length
        let t = $i.path | range ..-2
        for j in ($t | enumerate) {
            let desc = $i.g | get $j.index
            let g = $env.comma_index.settings.test_group
            if $j.index < $l {
                let a = $lv | get $j.index
                if $j.item == $a {
                } else {
                    do $g { indent: $j.index title: $j.item desc: $desc}
                }
            } else {
                do $g { indent: $j.index title: $j.item desc: $desc}
            }
        }
        test $i.fmt ($i.indent - 1) $i.desc {
            expect: $i.expect
            spec: $i.spec
            args: $i.mock
            report: $i.report
            scope: (resolve scope null (resolve comma 'comma_scope') [])
        }
        $lv = $t
    }
}

def 'run test' [tbl --watch: bool] {
    let argv = $in
    let _ = $env.comma_index
    let bc = {|node, _|
        if $_.dsc in $node {
            $node | get $_.dsc
        } else {
            ''
        }
    }
    let cb = {|pth, g, node, _|
        let indent = ($pth | length)
        if $_.exp in $node {
            let exp = $node | get $_.exp
            let spec = $node | get $_.act
            let mock = if $_.mock in $node { $node | get $_.mock }
            let report = if $_.rpt in $node { $node | get $_.rpt }
            let desc = $pth | last
            {
                path: $pth
                g: $g
                fmt: $env.comma_index.settings.test_message
                indent: $indent
                desc: $desc
                expect: $exp
                spec: $spec
                mock: $mock
                report: $report
            }
        }
    }
    let specs = $argv
    | flatten
    | tree select --strict $tbl
    | do {
        let i = $in
        if $_.sub in $i.node {
            $i.node | get $_.sub
        } else {
            let n = $argv | last
            {$n: ($i.node | reject 'end') }
        }
    }
    | tree map $cb $bc
    if ($watch | default false) {
        run watch {
            $specs | test suit
        } [] {} { clear: true }
    } else {
        $specs | test suit
    }
}

def summary [$tbl] {
    let argv = $in
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

def 'tree map' [cb bc?] {
    let t = $in | resolve node
    let _ = $env.comma_index
    tree travel [] [] $t $cb $bc $_
}

def 'tree travel' [path g tree cb bc _] {
    if $tree.end {
        do $cb $path $g $tree $_
    } else {
        $tree | get $_.sub
        | transpose k v
        | reduce -f [] {|x, a|
            let v = $x.v | resolve node
            let g = if ($bc | describe -d).type == 'closure' {
                $g | append (do $bc $v $_)
            } else { $g }
            let r = tree travel ($path | append $x.k) $g $v $cb $bc $_
            if ($r | is-empty) {
                $a
            } else {
                $a | append $r
            }
        }
    }
}

def 'resolve scope' [args, vars, flts] {
    mut vs = {}
    mut cpu = []
    mut flt = {}
    let _ = $env.comma_index
    for i in ($vars | transpose k v) {
        if ($i.v | describe -d).type == 'record' {
            if $_.cpu in $i.v {
                $cpu ++= {k: $i.k, v: ($i.v | get $_.cpu)}
            } else if $_.flt in $i.v {
                $flt = ($flt | merge {$i.k: ($i.v | get $_.flt)} )
            } else {
                $vs = ($vs | merge {$i.k: $i.v})
            }
        } else {
            $vs = ($vs | merge {$i.k: $i.v})
        }
    }
    for i in $cpu {
        $vs = ($vs | merge {$i.k: (do $i.v $args $vs)} )
    }
    for i in ($flts | default []) {
        if $i in $flt {
            $vs = ($vs | merge {$i: (do ($flt | get $i) $args $vs)} )
        } else {
            error make -u {msg: $"filter `($i)` not found" }
        }
    }
    $vs
}

def 'os type' [] {
    let info = cat /etc/os-release
    | lines
    | reduce -f {} {|x, acc|
        let a = $x | split row '='
        $acc | upsert $a.0 ($a.1| str replace -a '"' '')
    }
    if 'ID_LIKE' in $info {
        if not ($info.ID_LIKE | parse -r '(rhel|fedora|redhat)' | is-empty) {
            'redhat'
        } else {
            $info.ID_LIKE
        }
    } else {
        $info.ID
    }
}


def 'resolve comma' [key = 'comma'] {
    let _ = $env.comma_index
    if ($env | get $key | describe -d).type == 'closure' {
        do ($env | get $key) $_
    } else {
        $env | get $key
    }
}

def 'run watch' [act argv scope w] {
    if $w == null { return }
    let _ = $env.comma_index
    let cl = $w.clear? | default false
    if 'interval' in $w {
        loop {
            if $cl {
                clear
            }
            do $act $argv $scope
            sleep $w.interval
            print $env.comma_index.settings.theme.watch_separator
        }
    } else {
        if $cl {
            clear
        }
        if not ($w.postpone? | default false) {
            do $act $argv ($scope | upsert $_.wth { op: null path: null new_path: null })
        }
        let ops = if ($w.op? | is-empty) {['Write']} else { $w.op }
        watch . --glob=($w.glob? | default '*') {|op, path, new_path|
            if $cl {
                clear
            }
            if $op in $ops {
                do $act $argv ($scope | upsert $_.wth {
                    op: $op
                    path: $path
                    new_path: $path
                })
                if not $cl {
                    print $env.comma_index.settings.theme.watch_separator
                }
            }
        }
    }
}

def run [tbl --watch: bool] {
    let n = $in | tree select --strict $tbl
    let _ = $env.comma_index
    if not $n.node.end {
        do $_.settings.tips "require argument" ($n.node | get $_.sub | columns)
        return
    }
    let flt = if $_.flt in $n.node { [...$n.filter ...($n.node | get $_.flt)] } else { $n.filter }
    let wth = if $watch {
        if $_.wth in $n.node {
            [...$n.watch ($n.node | get $_.watch)]
        } else {
            $n.watch
        }
        | reduce -f {} {|i,a| $a | merge $i}
    } else {
        null
    }
    let act = $n.node | get $_.act
    let scope = resolve scope $n.rest (resolve comma 'comma_scope') $flt

    if ($wth | is-empty) {
        do $act $n.rest $scope
    } else {
        run watch $act $n.rest $scope $wth
    }
}

def cmpl [tbl] {
    let n = $in
    let n = if ($n | last) == '' { $n | range ..-2 } else { $n }
    let n = $n | tree select $tbl
    let _ = $env.comma_index
    let flt = if $_.flt in $n.node { [...$n.filter ...($n.node | get $_.flt)] } else { $n.filter }
    let wth = if $_.wth in $n.node { $n.node | get $_.wth } else { null }
    if $n.node.end {
        let cmp = $n.node | get $_.cmp
        let scope = resolve scope null (resolve comma 'comma_scope') $flt
        do $cmp $n.rest $scope
    } else {
        $n.node | get $_.sub | transpose k v | each {|x| $x | update v ($x.v | resolve node) | enrich desc $flt }
    }
}

def 'enrich desc' [flt] {
    let o = $in
    let _ = $env.comma_index
    let flt = if $_.flt in $o.v {
        [...$flt, ...($o.v | get $_.flt)]
    } else {
        $flt
    }
    let f = if ($flt | is-empty) { '' } else { $"($flt | str join '|')|" }
    let w = if $_.wth in $o.v {
        let w = $o.v | get $_.wth
        if 'interval' in $w {
            $"[poll:($w.interval)]"
        } else {
            let ops = if ($w.op? | is-empty) {['Write']} else {$w.op}
            | str join ','
            $"[($ops)|($w.glob? | default '*')]"
        }
    } else { '' }

    let suf = $"($w)($f)"
    let suf = if ($suf | is-empty) { $suf } else { $"($suf) " }
    if ($o.v | describe -d).type == 'record' {
        let dsc = if $_.dsc in $o.v { $o.v | get $_.dsc } else { '' }
        if ($dsc | is-empty) {
            $o.k
        } else {
            { value: $o.k, description: $"($suf)($dsc)"}
        }
    } else {
        # TODO: ?
        { value: $o.k, description: $"__($suf)" }
    }
}

def 'gen vscode-tasks' [tbl] {
    let argv = $in
    let _ = $env.comma_index
    let bc = {|node, _|
        if $_.dsc in $node {
            $node | get $_.dsc
        } else {
            ''
        }
    }
    let cb = {|pth, g, node, _|
        let indent = ($pth | length)
        if $_.exp in $node {
            []
        } else {
            let label = $g
                | filter {|x| not ($x | is-empty) }
                | str join ' | '
            let command = $pth
                | str join ' '
            let id = if $_.cmp in $node { random chars -l 8 }
            {
                label: $label
                command: $command
                id: $id
            }
        }
    }
    let vs = $argv
    | flatten
    | tree select --strict $tbl
    | $in.node
    | reject 'end'
    | tree map $cb $bc
    let nuc = "nu -c 'use comma.nu *; source ,.nu;"
    let tasks = $vs
    | each {|x|
        let input = if ($x.id | is-empty) { '' } else { $" ${input:($x.id)}"}
        let label = if ($x.label | is-empty) { '' } else { $" [($x.label)]" }
        {
            type: 'shell'
            label: $"($x.command)"
            command: $"($nuc) , ($x.command)($input)'"
            problemMatcher: []
        }
    }
    let inputs = $vs
    | filter {|x| not ($x.id | is-empty) }
    | each {|x| {
        id: $x.id
        type: 'command'
        command: 'shellCommand.execute'
        args: { command: $"($nuc) , -c --vscode ($x.command)'" }
    } }
    {
        version: "2.0.0"
        tasks: $tasks
        inputs: $inputs
    }
}

def 'parse argv' [] {
    let context = $in
    $context.0
    | str substring 0..$context.1
    | split row -r '\s+'
    | range 1..
    | where not ($it | str starts-with '-')
}

def expose [t, a, tbl] {
    match $t {
        test => {
            $a | run test $tbl
        }
        summary => {
            $a | summary $tbl
        }
        vscode => {
            $a | gen vscode-tasks $tbl
        }
        _ => {
            let _ = $env.comma_index
            do $_.settings.tips "expose has different arguments" [test summary vscode]
        }
    }
}

export def --wrapped dry [...x] {
    if (do -i { $env.comma_index | get $env.comma_index.dry_run } | default false) {
        $"($x | flatten | str join ' ')"
    } else {
        ^$x.0 ($x | range 1..)
    }
}

def 'run completion' [...context] {
    $context
    | parse argv
    | cmpl (resolve comma)
}

export def --wrapped , [
    # flag with parameters is not supported
    --json (-j)
    --completion (-c)
    --vscode
    --test (-t)
    --tag (-g)
    --watch (-w)
    --dry-run (-d)
    --expose (-e) # for test
    ...args:string@'run completion'
] {
    if ($args | is-empty) {
        if $vscode {
            let c = $args | gen vscode-tasks (resolve comma)
            if $json {
                $c | to json
            } else {
                $c
            }
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
            let c = $args | flatten | cmpl $tbl
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
            $args | flatten | run test $tbl --watch $watch
        } else if $expose {
            expose $args.0 ($args | range 1..) $tbl
        } else {
            if $dry_run {
                $env.comma_index = ($env.comma_index | upsert $env.comma_index.dry_run true)
            }
            $args | flatten | run $tbl --watch $watch
        }
    }
}
