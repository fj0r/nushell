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

export def batch [
    ...modules
    --bare (-b)
    --init (-i)
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
    mut cmd = if $init { [
        $'source ($nu.env-path)'
        $'source ($nu.config-path)'
    ] } else { [] }
    if not $bare {
        $cmd ++= 'use comma *'
    }
    $cmd ++= $modules
    $cmd ++= $o
    $cmd = ($cmd | str join (char newline))
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
