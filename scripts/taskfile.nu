export def unindent [] {
    let txt = $in | lines | range 1..
    let indent = $txt.0 | parse --regex '^(?P<indent>\s*)' | get indent.0 | str length
    $txt
    | each {|s| $s | str substring $indent.. }
    | str join (char newline)
}


export def new [filename:string = ','] {
    '
    export def main [...args:string@compos] {
        match $args.0 {

        }
    }

    def compos [context: string, offset: int] {
        let argv = $context | str substring 0..$offset | split row -r "\\s+" | range 1..
        match ($argv | length) {
            1 => []
            2 => []
            _ => []
        }
    }
    '
    | unindent
    | save $"($filename).nu"
}
