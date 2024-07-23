export-env {
    $env.OLLAMA_HOST = 'http://localhost:11434'
}

def 'nu-complete models' [] {
    http get $"($env.OLLAMA_HOST)/api/tags"
    | get models
    | each {{value: $in.name, description: $in.modified_at}}
}

export def 'ollama info' [model: string@'nu-complete models'] {
    http post --content-type application/json $"($env.OLLAMA_HOST)/api/show" {name: $model}
}
