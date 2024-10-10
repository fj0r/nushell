use common.nu *

export def 'todo format' [--md --md-list] {
    let i = $in
    $i | to tree | fmt tree --md=$md --md-list=$md_list
}

def 'to tree' [] {
    let i = $in
    # dynamically determines the root node
    let rid = $i | get parent_id | uniq | filter { $in not-in ($i | get id)}
    let root = $i | where parent_id in $rid
    if ($root | is-empty) { return }
    to-tree $root ($i | group-by parent_id)
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

def 'fmt tree' [level:int=0 --indent(-i):int=4 --md --md-list] {
    mut out = []
    for i in $in {
        let n = '' | fill -c ' ' -w ($level * $indent)
        for j in ($i | reject sub | fmt leaves $n --md=$md --md-list=$md_list) {
            $out ++= $j
        }
        if ($i.sub | is-not-empty) {
            $out ++= $i.sub | fmt tree ($level + 1) --md=$md --md-list=$md_list
        }
    }
    $out | flatten | str join (char newline)
}

def 'fmt leaves' [
    indent
    --md
    --md-list
] {
    let o = $in
    let color = $env.TODO_THEME.color
    let formatter = $env.TODO_THEME.formatter
    let endent = $"($indent)   "

    let done = $env.TODO_THEME.symbol.box | get ($md | into int) | get $o.done
    let title = if $md_list {
        [$"($indent)-" $o.title $"#($o.id)"]
    } else if $md {
        [$"($indent)-" $done $o.title $"#($o.id)"]
    } else {
        [$indent $done $"(ansi $color.title)($o.title)" $"(ansi $color.id)#($o.id)"]
    }

    let tags = if (not $md) and ($o.tags? | is-not-empty) {
        $o.tags
        | filter { $in | is-not-empty }
        | split-cat
        | items {|k,v| $"(ansi $color.cat)($k):(ansi $color.tag)($v | str join '/')"}
    } else { [] }

    let meta = [important urgent challenge created updated]
    | if $o.done == 0 { $in | append 'deadline' } else { $in }
    | each {|x|
        let y = $o | get -i $x
        let z = match ($y | describe) {
            int => $y
            string => {$y | str length}
            _ => -1
        }
        if not $md and $z > 0 {
            $"(ansi ($color | get $x))(do ($formatter | get $x) $y $o)"
        }
    }

    let header = [...$title ...$tags ...$meta]
    | filter { $in | is-not-empty }
    | str join ' '
    |  if $md { $in } else { $"($in)(ansi reset)" }

    let body = if not $md {
        $o.description
        | lines
        | each {$"($endent)(ansi $color.description)($in)(ansi reset)"}
    } else { [] }

    [$header ...$body]
}

