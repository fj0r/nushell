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
    let s = data session
    let model = if ($model | is-empty) { $s.model } else { $model }
    let ct = $message | str replace -m $placehold $content
    let msg = { role: "user", content: $ct, ...$img }
    if $debug {
        print $"(ansi grey)($message)\n---\n($placehold)\n---(ansi reset)"
        print $"(ansi grey)($msg.content)\n---(ansi reset)"
    }
    if not $forget {
        data record $s.created $s.provider $model 'user' $ct 0
    }
    let r = http post -t application/json --headers [
        Authorization $"Bearer ($s.api_key)"
    ] $"($s.baseurl)/chat/completions" {
        model: $model
        messages: [
            ...(if $forget { [] } else { data messages })
            $msg
        ]
        temprature: $s.temperature
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
        data record $s.created $s.provider $model 'assistant' $r.msg $r.token
    }
    if $out { $r.msg }
}


export def "ai embed" [
    input: string
    --model(-m): string@"nu-complete models"
] {
    let s = data session
    let model = if ($model | is-empty) { $s.model } else { $model }
    http post -t application/json $"($s.baseurl)/embeddings" {
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

