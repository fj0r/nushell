use common.nu *
use completion.nu *
use data.nu
export use config.nu *

export-env {
    $env.OPENAI_SESSION = date now | format date '%FT%H:%M:%S.%f'
    data init
    data make-session $env.OPENAI_SESSION
}

export def --env "ai chat" [
    message: string
    --model(-m): string@"nu-complete models"
    --image(-i): path
    --forget(-f)
    --placehold(-p): string = '{}'
    --out(-o)
    --editor(-e)
    --temp(-t): string = 'send-message.XXX'
    --debug
] {
    let content = $in | default ""
    let content = if $editor {
        $content | block-editor $temp
    } else {
        $content
    }
    let img = if ($image | is-empty) {
        {}
    } else {
        {images: [(open $image | encode new-base64)]}
    }
    let msg = {
        role: "user"
        content: ($message | str replace -m $placehold $content)
        ...$img
    }
    if $debug {
        print $"(ansi grey)($message)\n---\n($placehold)\n---(ansi reset)"
        print $"(ansi grey)($msg.content)\n---(ansi reset)"
    }
    if not $forget {
        $env.OPENAI_CHAT = ($env.OPENAI_CHAT | update $model {|x| $x | get $model | append $msg})
    }

    let r = http post -t application/json --headers [
        Authorization $"Bearer ($env.OPENAI_API_KEY)"
    ] $"($env.OPENAI_BASEURL)/chat/completions" {
        model: $model
        messages: [
            ...(if $forget { [] } else { $env.OPENAI_CHAT | get $model })
            $msg
        ]
        temprature: $env.OPENAI_TEMPERATURE
        stream: true
    }
    | lines
    | reduce -f {msg: '', token: 0} {|i,a|
        let x = $i | parse -r '.*?(?<data>\{.*)'
        if ($x | is-empty) { return $a }
        let x = $x | get 0.data | from json
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
    if $out { $r.msg }
}


export def "ai embed" [
    input: string
    --model(-m): string@"nu-complete models"
] {
    http post -t application/json $"($env.OPENAI_BASEURL)/embeddings" {
        model: $model, input: [$input], encoding_format: 'float'
    }
    | get data.0.embedding
}

export def 'ai do' [
    ...args: string@"nu-complete role"
    --out(-o)
    --model(-m): string@"nu-complete models"
    --editor(-e)
    --debug
] {
    let input = if ($in | is-empty) {
        if $editor { '' } else { $args | last }
    } else { $in }
    let argv = if ($in | is-empty) {
        if $editor { $args | range 1..<-2 } else { $args | range 1..<-1 }
    } else { $args | range 1.. }
    let role = $env.OPENAI_PROMPT | get $args.0
    let placehold = $"<(random chars -l 6)>"
    let model = if ($model | is-empty) {
        $role | get model
    } else {
        $model
    }
    let prompt = $role | get prompt | each {|x|
        if ($x | str replace -ar "['\"`]+" '' | $in == '{}') {
            $x | str replace '{}' $placehold
        } else {
            $x
        }
    } | str join (char newline)
    let prompt = $argv | enumerate
    | reduce -f $prompt {|i,a|
        $a | str replace '{}' (($role.placeholder? | get $i.index) | get $i.item)
    }

    $input | ai chat -m $model -p $placehold --editor=$editor --temp prompt-XXX --out=$out --debug=$debug $prompt
}

