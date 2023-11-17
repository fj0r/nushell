export def new_taskfie [] {
    "
    export def main [...args:string@comp] {
        match $args.0 {

        }
    }

    def comp [context: string, offset: int] {
        let size = $context | str substring 0..$offset | split row ' ' | length
        if $size < 3 {
            []
        } else if $size < 4 {
            []
        }
    }
    " | save ,.nu
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
