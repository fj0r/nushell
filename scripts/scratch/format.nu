use common.nu *

export def scratch-format [--md --md-list] {
    $in | to tree | fmt tree --md=$md --md-list=$md_list
}

export def tag-format [--md --md-list] {
    $in
    | to tree
    | tag tree
    | fmt tag --md=$md --md-list=$md_list
}

# si 11
export def 'tag tree' [] {
    let o = $in
    # dynamically determines the root node
    let x = $o | each {|i|
        let main = $i.tags.0
        let node = $i | update tags {|x| $x.tags | range 1.. }
        {tags: main, node: node}
    }
    mut r = []
}

def tag-tree [tags node] {
}

def 'fmt tag' [
    level:int=0
    --indent(-i):int=4
    --padding(-p):int=0
    --md
    --md-list
] {

}

export def 'to tree' [] {
    let i = $in
    # dynamically determines the root node
    let all_ids = $i | get id | uniq
    let root_ids = $i | get parent_id | uniq | filter { $in not-in $all_ids }
    let root = $i | where parent_id in $root_ids
    if ($root | is-empty) { return }
    to-tree $root ($i | group-by parent_id)
}

def to-tree [root o] {
    $root | each {|i|
        let k = $i.id | into string
        let t = if $k in $o {
            to-tree ($o | get $k) $o
        } else {
            []
        }
        $i | insert children $t
    }
}

def 'fmt tree' [
    level:int=0
    --indent(-i):int=4
    --padding(-p):int=0
    --md
    --md-list
] {
    mut out = []
    for i in $in {
        let n = '' | fill -c ' ' -w ($padding + $level * $indent)
        for j in ($i | reject children | fmt leaves $n --md=$md --md-list=$md_list) {
            $out ++= $j
        }
        if ($i.children | is-not-empty) {
            $out ++= $i.children | fmt tree ($level + 1) --md=$md --md-list=$md_list
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
    let color = $env.SCRATCH_THEME.color
    let formatter = $env.SCRATCH_THEME.formatter
    let endent = $"($indent)   "

    let done = $env.SCRATCH_THEME.symbol.box | get ($md | into int) | get $o.done
    let title = if $md_list {
        [$"($indent)($env.SCRATCH_THEME.symbol.md_list)" $o.title $"#($o.id)"]
    } else if $md {
        [$"($indent)($env.SCRATCH_THEME.symbol.md_list)" $done $o.title $"#($o.id)"]
    } else {
        [$indent $done $"(ansi $color.title)($o.title)" $"(ansi $color.id)#($o.id)"]
    }
    let verbose = not $md and not $md_list

    let tags = if $verbose and ($o.tags? | is-not-empty) {
        let ct = ansi $color.tag
        $o.tags | each {|x| $"($ct)($x | str join ':')" }
        # :TODO:
        #| group-by cat
        #| items {|k,v| $"(ansi $color.cat)($k):(ansi $color.tag)($v.tag | str join '/')"}
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
        if $verbose and $z > 0 {
            $"(ansi ($color | get $x))(do ($formatter | get $x) $y $o)"
        }
    }

    let header = [...$title ...$tags ...$meta]
    | filter { $in | is-not-empty }
    | str join ' '
    |  if $verbose { $"($in)(ansi reset)" } else { $in }

    let body = if $verbose and ($o.body? | is-not-empty) {
        $o.body
        | lines
        | each {$"($endent)(ansi $color.body)($in)(ansi reset)"}
    } else { [] }

    [$header ...$body]
}
