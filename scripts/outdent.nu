export def main [indent?:int] {
    let txt = $in | lines
    if ($txt | length) < 2 { return $txt.0? }
    let indent = if ($indent | is-empty) {
        $txt.1 | parse --regex '^(?<indent>\s*)' | get indent.0 | str length
    } else {
        $indent
    }
    let body = $txt
    | range 1..
    | each {|s| $s | str substring $indent.. }
    if ($txt.0 | str trim | is-empty) {
        $body
    } else {
        $body | prepend $txt.0
    }
    | str join (char newline)
}

