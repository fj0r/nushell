def unindent [] {
    let txt = $in | lines | range 1..
    let indent = $txt.0 | parse --regex '^(?P<indent>\s*)' | get indent.0 | str length
    $txt
    | each {|s| $s | str substring $indent.. }
    | str join (char newline)
}

def 'path parents' [] {
    $in
    | path expand
    | path split
    | reduce -f [ '' ] {|x, acc| [( $acc.0 | path join $x ), ...$acc] }
    | range ..-2
}

def find [] {
    $in
    | path parents
    | filter {|x| $x | path join ',.nu' | path exists }
    | get 0?
}

def comma_file [] {
    [
        {
          condition: {|_, after| not ($after | path join ',.nu' | path exists)}
          code: "$env.comma = null"
        }
        {
          condition: {|_, after| $after | path join ',.nu' | path exists}
          code: "
          print $'(ansi default_underline)(ansi default_bold),(ansi reset).nu (ansi green_italic)detected(ansi reset)...'
          print $'(ansi yellow_italic)activating(ansi reset) (ansi default_underline)(ansi default_bold),(ansi reset) module with `(ansi default_dimmed)(ansi default_italic)source ,.nu(ansi reset)`'
          source ,.nu
          "
        }
    ]
}

export-env {
    $env.config = ( $env.config | upsert hooks.env_change.PWD { |config|
        let o = ($config | get -i hooks.env_change.PWD)
        let val = (comma_file)
        if $o == null {
            $val
        } else {
            $o | append $val
        }
    })
    $env.comma_index = ([sub dsc act cmp flt cpu wth] | gendict 5)
}

def gendict [size: int = 5] {
    let keys = $in
    mut k = []
    let n = $keys | length
    let rk = random chars -l ($n * $size)
    for i in 1..$n {
        let b = ($i - 1) * $size
        let e = $i * $size
        $k ++= ($rk | str substring $b..$e)
    }
    $keys
    | zip $k
    | reduce -f {} {|x, acc|
        $acc | upsert $x.0 $"($x.0)_($x.1)"
    }
}

def log [tag? -c] {
    let o = $in
    if ($c) {
        echo $'---(char newline)' | save -f ~/.cache/comma.log
    } else {
        echo $'---($tag)---($o | describe)(char newline)($o | to yaml)' | save -a ~/.cache/comma.log
    }
    $o
}

def 'as act' [] {
    let o = $in
    let _ = $env.comma_index
    let t = ($o | describe -d).type
    if $t == 'closure' {
        { $_.act: $o }
    } else if ($_.sub in $o) {
        null
    } else if ($_.act in $o) {
        $o
    } else {
        null
    }
}

def resolve-scope [args, vars, flts] {
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
            error make {msg: $"filter `($i)` not found" }
        }
    }
    $vs
}

def get-comma [key = 'comma'] {
    let _ = $env.comma_index
    if ($env | get $key | describe -d).type == 'closure' {
        let dict = $_ | merge {log: {$in | log}}
        do ($env | get $key) $dict
    } else {
        $env | get $key
    }
}

def run [tbl] {
    let loc = $in
    let _ = $env.comma_index
    mut act = $tbl
    mut argv = []
    mut flt = []
    for i in $loc {
        let a = $act | as act
        if ($a | is-empty) {
            if ($_.sub in $act) and ($i in ($act | get $_.sub)) {
                if $_.flt in $act {
                    $flt ++= ($act | get $_.flt)
                }
                let n = $act | get $_.sub | get $i
                $act = $n
            } else if $i in $act {
                let n = $act | get $i
                $act = $n
            } else {
                $act = {|| print $"not found `($i)`"}
                break
            }
        } else {
            $argv ++= $i
        }
    }
    let a = $act | as act
    if ($a | is-empty) {
        let c = if $_.sub in $act { $act | get $_.sub | columns } else { $act | columns }
        print $'require argument: ($c)'
    } else {
        if $_.flt in $a {
            $flt ++= ($a | get $_.flt)
        }
        let scope = (resolve-scope $argv (get-comma 'comma_scope') $flt)
        let cls = $a | get $_.act
        let argv = $argv
        if $_.wth in $a {
            let w = $a | get $_.wth
            if 'interval' in $w {
                loop {
                    do $cls $argv $scope
                    sleep $w.interval
                    print $"(ansi dark_gray)----------(ansi reset)"
                    if ($w.clear? | default false) {
                        clear
                    }
                }
            } else {
                let ops = if ($w.op? | is-empty) {['Write']} else { $w.op }
                watch . --glob=($w.glob? | default '*') {|op, path, new_path|
                    if $op in $ops {
                        do $cls $argv ($scope | upsert $_.wth {
                            op: $op
                            path: $path
                            new_path: $path
                        })
                    }
                }
            }
        } else {
            do $cls $argv $scope
        }
    }
}

def enrich-desc [flt] {
    let o = $in
    let _ = $env.comma_index
    let flt = if $_.flt in $o.v { [...$flt, ...($o.v | get $_.flt)] } else { $flt }
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

def complete [tbl] {
    let argv = $in
    let _ = $env.comma_index
    mut tbl = (get-comma)
    mut flt = []
    for i in $argv {
        let c = if ($i | is-empty) {
            $tbl
        } else {
            let tp =  ($tbl | describe -d).type
            if ($tp == 'record') and ($i in $tbl) {
                let j = $tbl | get $i
                if $_.sub in $j {
                    if $_.flt in $j {
                        $flt ++= ($j | get $_.flt)
                    }
                    $j | get $_.sub
                } else {
                    $j
                }
            } else {
                $tbl
            }
        }
        let a = $c | as act
        if not ($a | is-empty) {
            # TODO: leaf flt
            let r = do ($a | get $_.cmp) $argv (resolve-scope null (get-comma 'comma_scope') $flt)
            $tbl = $r
        } else {
            $tbl = $c
        }
    }
    let flt = $flt
    match ($tbl | describe -d).type {
        record => {
            $tbl
            | transpose k v
            | each {|x|
                if ($x.v | describe -d).type == 'closure' {
                    $x.k
                } else {
                    $x | enrich-desc $flt
                }
            }
        }
        list => { $tbl }
        _ => { $tbl }
    }
}

def summary [] {
    let o = $in
    $o
}

def 'parse argv' [] {
    let context = $in
    $context.0
    | str substring 0..$context.1
    | split row -r '\s+'
    | range 1..
    | where not ($it | str starts-with '-')
}

def compos [...context] {
    $context
    | parse argv
    | complete (get-comma)
}

export def --wrapped , [
    --summary
    --completion
    ...args:string@compos
] {
    if $summary {
        let r = get-comma | summary | to json
        return $r
    }
    if $completion {
        return
    }
    if ($args | is-empty) {
        if ([$env.PWD, ',.nu'] | path join | path exists) {
            ^$env.EDITOR ,.nu
        } else {
            let a = [yes no] | input list 'create ,.nu?'
            if $a == 'yes' {
                $"
                $env.comma_scope = {|_|{
                    created: '(date now | format date '%Y-%m-%d{%w}%H:%M:%S')'
                    computed: {$_.cpu:{|a, s| $'\($s.created\)\($a\)' }}
                    say: {|s| print $'\(ansi yellow_italic\)\($s\)\(ansi reset\)' }
                    quick: {$_.flt:{|a, s| do $s.say 'run a `quick` filter' }}
                    slow: {$_.flt:{|a, s|
                        do $s.say 'run a `slow` filter'
                        sleep 1sec
                        do $s.say 'filter need to be declared'
                        sleep 1sec
                        $'\($s.computed\)<\($a\)>'
                    }}
                }}

                $env.comma = {|_|{
                    created: {|a, s| $s.computed }
                    open: {
                        $_.sub: {
                            any: {
                                $_.act: {|a, s| open $a.0}
                                $_.cmp: {ls | get name}
                                $_.dsc: 'open a file'
                            }
                            json: {
                                $_.act: {|a, s| $s | get $_.wth }
                                $_.cmp: {ls *.json | get name}
                                $_.dsc: 'open a json file'
                                $_.wth: {
                                    glob: '*.json'
                                    op: ['Write', 'Create']
                                }
                            }
                            scope: {
                                $_.act: {|a, s| print $'args: \($a\)'; $s }
                                $_.flt: ['slow']
                                $_.dsc: 'open scope'
                                $_.wth: {
                                    interval: 2sec
                                }
                            }
                        }
                        $_.dsc: 'open something'
                        $_.flt: ['quick']
                    }
                }}
                "
                | unindent
                | save $",.nu"
                #source ',.nu'
            }
        }
    } else {
        $args | run (get-comma)
    }
}
