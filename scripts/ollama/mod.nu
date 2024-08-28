export-env {
    $env.OLLAMA_HOST = "http://localhost:11434"
    $env.OLLAMA_CHAT = {}
}

def "nu-complete models" [] {
    http get $"($env.OLLAMA_HOST)/api/tags"
    | get models
    | each {{value: $in.name, description: $in.modified_at}}
}

export def "ollama info" [model: string@"nu-complete models"] {
    http post -t application/json $"($env.OLLAMA_HOST)/api/show" {name: $model}
}

export def "ollama embed" [
    model: string@"nu-complete models"
    input: string
] {
    http post -t application/json $"($env.OLLAMA_HOST)/api/embed" {
        model: $model, input: [$input]
    }
    | get embeddings.0
}


export def "ollama gen" [
    model: string@"nu-complete models"
    prompt: string
    --image(-i): path
    --full(-f)
] {
    let content = $in | default ""
    let img = if ($image | is-empty) {
        {}
    } else {
        {images: [(open $image | encode base64)]}
    }
    let r = http post -t application/json $"($env.OLLAMA_HOST)/api/generate" {
        model: $model
        prompt: ($prompt | str replace "{}" $content)
        stream: false
        ...$img
    }
    if $full {
        $r
    } else {
        $r.response
    }
}


export def --env "ollama chat" [
    model: string@"nu-complete models"
    message: string
    --image(-i): path
    --full(-f)
    --reset(-r)
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
    if ($env.OLLAMA_CHAT | is-empty) {
        $env.OLLAMA_CHAT = ($env.OLLAMA_CHAT | insert $model [])
    }
    if $reset {
        $env.OLLAMA_CHAT = ($env.OLLAMA_CHAT | update $model [])
    }
    $env.OLLAMA_CHAT = ($env.OLLAMA_CHAT | update $model {|x| $x | get $model | append $msg})
    let r = http post -t application/json $"($env.OLLAMA_HOST)/api/chat" {
        model: $model
        messages: [
            ...($env.OLLAMA_CHAT | get $model)
            $msg
        ]
        stream: false
    }
    $env.OLLAMA_CHAT = ($env.OLLAMA_CHAT | update $model {|x| $x | get $model | append $r.message})
    if $full {
        $r
    } else {
        $r.message.content
    }
}


export def --env "ollama live" [
    model: string@"nu-complete models"
    message: string
    --image(-i): path
    --full(-f)
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
    let data = {
        model: $model
        messages: [
            $msg
        ]
        stream: true
    }
    curl ...[
        -sL
        -X POST
        -H "Content-Type: application/json"
        $"($env.OLLAMA_HOST)/api/chat"
        -d $"($data | to json -r)"
    ]
    | from json -o
    | each { print -n $in.message.content }

    ""
}

export def similarity [a b] {
    if ($a | length) != ($b | length) {
        print "The lengths of the vectors must be equal."
    }
    $a | zip $b | reduce -f {p: 0, a: 0, b: 0} {|i,a|
        {
            p: ($a.p + ($i.0 * $i.1))
            a: ($a.a + ($i.0 * $i.0))
            b: ($a.b + ($i.1 * $i.1))
        }
    }
    | $in.p / (($in.a | math sqrt) * ($in.b | math sqrt))
}
