use data.nu

export def "nu-complete models" [] {
    let s = data session
    http get --headers [
        Authorization $"Bearer ($s.api_key)"
        OpenAI-Organization $s.org_id
        OpenAI-Project $s.project_id
    ] $"($s.baseurl)/models"
    | get data.id
}


export def 'nu-complete role' [ctx] {
    let args = $ctx | split row '|' | last | str trim -l | split row ' ' | range 2..
    let len = $args | length
    match $len {
        1 => {
            open $env.OPENAI_DB | query db "select name as value, description from prompt"
        }
        _ => {
            let d = open $env.OPENAI_DB | query db $"select * from prompt where name = '($args.0)'"
            $d | first | get placeholder | from json | get ($len - 2) | columns
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

export def "nu-complete provider" [] {
    let current = open $env.OPENAI_DB
    | query db $"select provider from sessions where created = '($env.OPENAI_SESSION)'"
    | get provider
    open $env.OPENAI_DB | query db $'select name, active from provider'
    | each {|x|
        let a = if $x.active > 0 {'*'} else {''}
        let c = if $x.name in $current {'+'} else {''}
        {value: $x.name, description: $"($c)($a)"}
    }
}

export def "nu-complete prompt" [] {
    open $env.OPENAI_DB
    | query db $"select name from prompt"
    | get name
}

export def "nu-complete temperature" [] {
    let s = data session
    let tr = ($s.temp_max - $s.temp_min) / 5
    0..5 | each { $in * $tr }
}
