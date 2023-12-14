export def unindent [] {
    let txt = $in | lines | range 1..
    let indent = $txt.0 | parse --regex '^(?P<indent>\s*)' | get indent.0 | str length
    $txt
    | each {|s| $s | str substring $indent.. }
    | str join (char newline)
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

