use common.nu *

export def 'todo format' [--md] {
    let i = $in
    $i | to tree | fmt tree --md=$md
}

def 'to tree' [] {
    let r = $in | group-by parent_id
    to-tree ($r | get '-1') $r
}

def to-tree [r o] {
    $r | each {|i|
        let k = $i.id | into string
        let t = if $k in $o {
            to-tree ($o | get $k) $o
        } else {
            []
        }
        $i | insert sub $t
    }
}

def 'fmt tree' [level:int=0 --indent(-i):int=4 --md] {
    for i in $in {
        let n = '' | fill -c ' ' -w ($level * $indent)
        $i | reject sub | fmt leaves $n --md=$md | each { print $in }
        if ($i.sub | is-not-empty) {
            $i.sub | fmt tree ($level + 1) --md=$md
        }
    }
}

def 'fmt leaves' [
    indent
    --md
] {
    let o = $in
    let endent = $"($indent)   "
    let leader = if $md {$"($indent)-"} else {$"($indent)"}
    let done = if $md {
        match $o.done {
            1 => '[x]'
            0 => '[ ]'
        }
    } else {
        match $o.done {
            1 => '🗹'
            0 => '☐'
        }
    }
    let id = if $md {''} else {$o.id}
    let tags = if not $md {$o.tags | fmt tags}
    let title = [
        $leader
        $done
        $"(ansi default_bold)($o.title)"
        $"(ansi grey)($id)"
        $tags
        (ansi reset)
    ] | filter { $in | is-not-empty } | str join ' '

    let created =  if not $md { $"(ansi xterm_lightslategrey)($o.created)" }
    let updated =  if not $md { $"(ansi xterm_rosybrown)($o.updated | into datetime | date humanize)" }
    let time = if not $md {$"($endent)($created) ($updated)(ansi reset)"}

    let desc = if not $md {
        $o.description
        | lines
        | each {$"($endent)(ansi grey)($in)(ansi reset)"}
        | str join (char newline)
    }

    let important = if not $md and $o.important > 0 {
        $"(ansi yellow)('' | fill -c '☆ ' -w $o.important)"
    }
    let urgent = if not $md and $o.urgent > 0 {
        $"(ansi red)('' | fill -c (char elevated) -w $o.urgent)"
    }
    let deadline = if not $md and ($o.deadline | is-not-empty) {
        $"(ansi grey)($o.deadline)"
    }

    let info = [$important $urgent $deadline] | filter { $in | is-not-empty }
    let info = if ($info | is-not-empty) {
        $info | append (ansi reset) | str join ' ' | $"($endent)($in)"
    }

    [$title $time $info $desc] | filter { $in | is-not-empty }
}

def 'fmt tags' [] {
    $in
    | split-cat
    | items {|k,v|
        $"(ansi green)($k):(ansi grey)($v | str join ',')"
    }
    | str join ' '
    | $"($in)(ansi reset)"
}
