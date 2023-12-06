export def unindent [] {
    let txt = $in | lines | range 1..
    let indent = $txt.0 | parse --regex '^(?P<indent>\s*)' | get indent.0 | str length
    $txt
    | each {|s| $s | str substring $indent.. }
    | str join (char newline)
}


export def new [filename:string = ','] {
    $"
    def --env export-environment [] {
        $env.created_at = '(date now | format date '%Y-%m-%d[%w]%H:%M:%S')'
    }



    export def main [...args:string@compos] {
        export-environment
        match $args.0? {
            _ => {
                print $\"created: \($env.created_at)\" 
            }
        }
    }

    def compos [...context] {
        $context | completion-generator from tree {}
    }
    "
    | unindent
    | save $"($filename).nu"
}
