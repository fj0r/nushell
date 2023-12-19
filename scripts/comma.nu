export def unindent [] {
    let txt = $in | lines | range 1..
    let indent = $txt.0 | parse --regex '^(?P<indent>\s*)' | get indent.0 | str length
    $txt
    | each {|s| $s | str substring $indent.. }
    | str join (char newline)
}

export def 'path parents' [] {
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

def pwd_module [] {
    [
        {
          condition: {|_, after| not ($after | path join ',.nu' | path exists)}
          code: "hide ,"
        }
        {
          condition: {|_, after| $after | path join ',.nu' | path exists}
          code: "
          print $'(ansi default_underline)(ansi default_bold),(ansi reset) module (ansi green_italic)detected(ansi reset)...'
          print $'(ansi yellow_italic)activating(ansi reset) (ansi default_underline)(ansi default_bold),(ansi reset) module with `(ansi default_dimmed)(ansi default_italic)use ,.nu(ansi reset)`'
          use ,.nu
          "
        }
    ]
}

export-env {
    $env.config = ( $env.config | upsert hooks.env_change.PWD { |config|
        let o = ($config | get -i hooks.env_change.PWD)
        let val = (pwd_module)
        if $o == null {
            $val
        } else {
            $o | append $val
        }
    })
}

def first-type [type] {
    for i in $in {
        if ($i | describe -d).type == $type {
            return $i
        }
    }
}

export def run [tbl] {
    let loc = $in
    mut act = $tbl
    mut arg = []
    for i in $loc {
        if ($act | describe -d).type == 'closure' {
            $arg ++= [$i]
        } else {
            if ($i in $act) {
                let n = $act | get $i
                if ($n | describe -d).type == 'list' {
                    $act = $n.0
                } else {
                    $act = $n
                }
            } else {
                $act = {|| print $"not found `($i)`"}
                break
            }
        }
    }
    let at = ($act | describe -d).type
    match $at {
        closure => { do $act $arg }
        record => { print $'require argument: ($act | columns)' }
        _ => { 'oops' }
    }
}

export def 'parse argv' [] {
    let context = $in
    $context.0
    | str substring 0..$context.1
    | split row -r '\s+'
    | range 1..
    | where not ($it | str starts-with '-')
}

export def log [] {
    let o = $in
    if ($o | is-empty) {
        echo $'---(char newline)' | save -f ~/.cache/comma.log
    } else {
        $o | to yaml | save -a ~/.cache/comma.log
    }
    $o
}

export def complete [tbl] {
    let argv = $in
    mut tbl = $env.comma
    for i in ($argv | default []) {
        let c = if ($i | is-empty) { $tbl } else { $tbl | get $i }
        if ($c | describe -d).type == 'list' {
            if ($c.0 | describe -d).type == 'closure' {
                let x = $c | range 1.. | first-type 'closure'
                $tbl = (do $x)
            } else {
                $tbl = $c.0
            }
        } else {
            $tbl = $c
        }
    }
    match ($tbl | describe -d).type {
        record => {
            $tbl
            | transpose k v
            | each {|x|
                if ($x.v | describe -d).type == 'list' {
                    let d = $x.v | range 1.. | first-type 'string'
                    { value: $x.k, description: $d }
                } else {
                    $x.k
                }
            }
        }
        _ => { $tbl }
    }
}

export def new [filename:string = ','] {
    $"
    export-env {
        $env.comma = {
            created-at: { '(date now | format date '%Y-%m-%d[%w]%H:%M:%S')' }
            hello: [{|x| print $'hello \($x\)' }, 'hello \(x\)']
            edit: { ^$env.EDITOR ,.nu }
            a: {
                b: {
                    c: [{|x| print $x }, 'description', {|| ls | get name } ]
                    d: { pwd }
                }
                x: [
                    {
                        y: [{|x| print y}, {|| [y1 y2 y3]}, 'description']
                    },
                    'xxx'
                ]
            }
        }
    }

    def compos [...context] {
        $context
        | comma parse argv
        | comma complete $env.comma
    }

    export def main [...args:string@compos] {
        $args | comma run $env.comma
    }
    "
    | unindent
    | save $"($filename).nu"
}

