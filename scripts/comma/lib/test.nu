def 'run exp' [expect result o] {
    let r = do $expect $result $o.args? $o.scope?
    if ($r | describe -d).type == 'bool' { $r } else {
        error make -u {msg: $"(view source $o.expect) must be bool" }
    }
}

export def diffo [x] {
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

export def main [fmt, indent, dsc, o] {
    let args = $o.args?
    let result = do $o.spec? $args $o.scope? | default false
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
            args: $args
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
        args: $args
        report: $report
    }
}

def suit [] {
    let specs = $in
    use resolve.nu
    mut lv = []
    for i in $specs {
        let l = $lv | length
        if not $i.end {
            do $env.comma_index.settings.test_group { indent: ($i.indent - 1), title: $i.desc, desc: ($i.g | last)}
            continue
        }
        let scope = resolve scope null (resolve comma 'comma_scope') [] --mode 'test'
        let args = $i.mock
        let args = if ($args | describe -d).type == 'closure' {
            do $args $scope
        } else {
            $args
        }
        let args = if ($args | describe -d).type == 'list' {
            if ($args.0? | describe -d).type == 'list' {
                $args
            } else {
                [$args]
            }
        } else {
            [[$args]]
        }
        for a in $args {
            main $i.fmt ($i.indent - 1) $i.desc {
                expect: $i.expect
                spec: $i.spec
                args: $a
                report: $i.report
                scope: $scope
            }
        }
    }
}


export def run [tbl --opt: record] {
    let argv = $in
    let _ = $env.comma_index
    use tree.nu
    let cb = {|pth, g, node, _, end|
        let indent = ($pth | length)
        let desc = $pth | last
        if $end {
            if $_.exp in $node {
                let exp = $node | get $_.exp
                let spec = $node | get $_.act
                let mock = if $_.mock in $node { $node | get $_.mock }
                let report = if $_.rpt in $node { $node | get $_.rpt }
                {
                    end: $end
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
        } else {
            {
                end: $end
                path: $pth
                g: $g
                fmt: $env.comma_index.settings.test_message
                indent: $indent
                desc: $desc
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
    | tree map $cb 'get_desc' --with-branch
    if ($opt.watch? | default false) {
        use run.nu watches
        watches {
            $specs | suit
        } [] {} { clear: true }
    } else {
        $specs | suit
    }
}
