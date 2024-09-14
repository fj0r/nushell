export-env {
    $env.OPENAI_HOST = "http://localhost:11434"
    $env.OPENAI_CHAT = {}
    $env.OPENAI_API_KEY = 'secret'
    $env.OPENAI_ORG_ID = ''
    $env.OPENAI_PROJECT_ID = ''
}


def "nu-complete models" [] {
    http get --headers [
        Authorization $"Bearer ($env.OPENAI_API_KEY)"
        OpenAI-Organization $env.OPENAI_ORG_ID
        OpenAI-Project $env.OPENAI_PROJECT_ID
    ] $"($env.OPENAI_HOST)/v1/models"
    | get data.id
}


export def --env "openai chat" [
    model: string@"nu-complete models"
    message: string
    --image(-i): path
    --reset(-r)
    --forget(-f)
] {
    let content = $in | default ""
    let img = if ($image | is-empty) {
        {}
    } else {
        {images: [(open $image | encode base64)]}
    }
    let msg = {
        role: "user"
        content: ($message | str replace "{}" $content)
        ...$img
    }
    if not $forget {
        if ($env.OPENAI_CHAT | is-empty) or ($model not-in $env.OPENAI_CHAT) {
            $env.OPENAI_CHAT = ($env.OPENAI_CHAT | insert $model [])
        }
        if $reset {
            $env.OPENAI_CHAT = ($env.OPENAI_CHAT | update $model [])
            print '✨'
        }
        $env.OPENAI_CHAT = ($env.OPENAI_CHAT | update $model {|x| $x | get $model | append $msg})
    }

    let r = http post -t application/json --headers [
        Authorization $"Bearer ($env.OPENAI_API_KEY)"
    ] $"($env.OPENAI_HOST)/v1/chat/completions" {
        model: $model
        messages: [
            ...(if $forget { [] } else { $env.OPENAI_CHAT | get $model })
            $msg
        ]
        stream: true
    }
    | reduce -f {msg: '', token: 0} {|i,a|
        let x = $i | parse -r '.*?(?<data>\{.*)' | get 0.data | from json
        let m = $x.choices | each { $in.delta.content } | str join
        print -n $m
        $a
        | update msg {|x| $x.msg + $m }
        | update token {|x| $x.token + 1 }
    }
    if not $forget {
        let r = {role: 'assistant', content: $r.msg, token: $r.token}
        $env.OPENAI_CHAT = ($env.OPENAI_CHAT | update $model {|x| $x | get $model | append $r })
    }
}


export def "openai embed" [
    model: string@"nu-complete models"
    input: string
] {
    http post -t application/json $"($env.OPENAI_HOST)/v1/embeddings" {
        model: $model, input: [$input], encoding_format: 'float'
    }
    | get data.0.embedding
}
