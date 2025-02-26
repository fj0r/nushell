def image-loader [uri: string] {
    let img = if ($uri | path exists) {
        let b =  open $uri | encode base64
        let t = $uri | path parse | get extension | str downcase
        let t = match $t {
            'jpg' | 'jpeg' => 'jpeg'
            _ => $t
        }
        {url: $"data:image/($t);base64,($b)"}
    } else {
        $uri
    }
}

export def req [
    --role(-r): string = 'user'
    --image(-i): string
    --audio(-a): string
    --tool-calls: string
    --tool-call-id: string
    --functions(-f): list<any>
    --model(-m): string
    --temperature(-t): number = 0.5
    --stream
    message?: string
] {
    mut o = $in | default { messages: [] }
    if $role not-in [user assistant system tool function] {
        error make { msg: $"unsupport role ($role)"}
    }
    if ($model | is-not-empty) {
        $o.model = $model
    }
    if ($temperature | is-not-empty) {
        $o.temperature =  $temperature
    }
    if ($functions | is-not-empty) {
        $o.tools = $functions
        $o.tool_choice = 'auto'
    }
    $o.stream = $stream
    let content = if not (($image | is-empty) and ($audio | is-empty)) {
        mut content = []
        if ($message | is-not-empty) {
            $content ++= [{type: text, text: $message}]
        }
        if ($image | is-not-empty) {
            $content ++= [{type: image_url, image_url: (image-loader $image) }]
        }
        $content
    } else {
        $message
    }

    mut m = {role: $role, content: $content}
    if ($tool_calls | is-not-empty) {
        $m.tool_calls = $tool_calls
    }
    if ($tool_call_id | is-not-empty) {
        $m.tool_call_id = $tool_call_id
    }

    if ($content | is-not-empty) or ($tool_calls | is-not-empty) {
        $o.messages = $o.messages ++ [$m]
    }

    $o
}

export def req-restore [s req] {
    $in
    | reduce -f $req {|i, a|
        match $i.role {
            assistant => {
                $a | ai-req $s -r $i.role $i.content --tool-calls ($i.tool_calls | from yaml)
            }
            tool => {
                $a | ai-req $s -r $i.role $i.content --tool-call-id $i.tool_calls
            }
            _ => {
                $a | ai-req $s -r $i.role $i.content
            }
        }
    }
}

export def merge-tools [tools] {
    if ($tools | is-empty) {
        []
    } else {
        $tools
        | each {|x|
            let v = $x
            | upsert id {|y| [($y.id? | default '')] }
            | upsert function.name {|y| [($y.function?.name? | default '')] }
            | upsert function.arguments {|y|
                [($y.function?.arguments? | default '')]
            }
            let k = $x.index? | default 0
            {$k: $v}
        }
        | reduce {|i,a|
            $a | merge deep $i --strategy=append
        }
        #| do {let a = $in; print ($a | table -e); return $a}
        | items {|k, v| $v }
        | update id {|y| $y.id | str join }
        | update function.name {|y| $y.function.name | str join }
        | update function.arguments {|y| $y.function.arguments | str join }
    }
}

export def call [
    session
    --quiet(-q)
] {
    let $req = $in
    http post -r -e -t application/json --headers [
            Authorization $"Bearer ($session.api_key)"
    ] $"($session.baseurl)/chat/completions" $req
    | lines
    | reduce -f {msg: '', reason: '', token: 0, tools: []} {|i,a|
        let x = $i | parse -r '.*?(?<data>\{.*)'
        if ($x | is-empty) { return $a }
        let x = $x | get 0.data | from json

        if 'error' in $x {
            error make {
                msg: ($x.error | to yaml)
            }
        }

        $x.choices
        | reduce -f $a {|i, a|
            let s = $i.delta.content? | default ''
            let r = $i.delta.reasoning_content? | default ''
            let t = $i.delta.tool_calls? | default []
            if not $quiet {
                if ($r | is-not-empty) {
                    print -n $"(ansi $env.AI_CONFIG.tool_calls)($r)(ansi reset)"
                }
                if ($s | is-empty) and ($r | is-empty) and ($t | is-empty) {
                    print (char newline)
                }
                print -n $s
            }
            let cf = $env.AI_CONFIG.finish_reason
            if $cf.enable and ($i.finish_reason? | is-not-empty) {
                print -e $"(ansi $cf.color)<($i.finish_reason)>(ansi reset)"
            }
            $a
            | update msg {|x| $x.msg + $s }
            | update reason {|x| $x.reason + $r }
            | update tools {|x| $x.tools ++ $t }
        }
        | update token {|x| $x.token + 1 }
    }
    | update tools {|x| merge-tools $x.tools }
}


export def models [] {

}

