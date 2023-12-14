export def 'filter index' [...idx] {
    reduce -f [] {|it, acc|
        if $it.index not-in ($idx|flatten) {
            $acc.item | append $it.item
        } else {
            $acc.item
        }
    }
}

export def 'path parents' [] {
    $in
    | path expand
    | path split
    | reduce -f [ '' ] {|x, acc| [( $acc.0 | path join $x ), ...$acc] }
    | range ..-2
}

export def unindent [] {
    let txt = $in | lines | range 1..
    let indent = $txt.0 | parse --regex '^(?P<indent>\s*)' | get indent.0 | str length
    $txt
    | each {|s| $s | str substring $indent.. }
    | str join (char newline)
}

def "nu-complete ps" [] {
    ps -l | each {|x| { value: $"($x.pid)", description: $x.command } }
}

export def wait-pid [pid: string@"nu-complete ps" action] {
    do -i { tail --pid $pid -f /dev/null }
    do $action
}

export def watch-write [path act -d:int=200 -g:string='*'] {
    watch -d $d -g $g $path {|op, path, new_path|
        if $op == 'Write' { do $act $path $new_path }
    }
}

