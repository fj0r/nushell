use data.nu *

export def "nu-complete models" [] {
    let r = data session
    http get --headers [
        Authorization $"Bearer ($r.api_key)"
        OpenAI-Organization $r.org_id
        OpenAI-Project $r.project_id
    ] $"($r.baseurl)/models"
    | get data.id
}


export def 'nu-complete role' [ctx] {
    let args = $ctx | split row '|' | last | str trim -l | split row ' ' | range 2..
    let len = $args | length
    match $len {
        1 => {
            $env.OPENAI_PROMPT | items {|k, v| {value: $k, description: $v.description? } }
        }
        _ => {
            let role = $env.OPENAI_PROMPT | get $args.0
            let ph = $role.placeholder? | get ($len - 2)
            $ph | columns
        }
    }
}


export def "nu-complete config" [context] {
    let ctx = $context | split row -r '\s+' | range 3..
    if ($ctx | length) < 2 {
        return [provider, prompt]
    } else {
        open $env.OPENAI_DB | query db $'select name from ($ctx.0)' | get name
    }
}

