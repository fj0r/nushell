export def --wrapped 'mdurl' [
    ...args
    --transform(-t): closure
    --summary(-s)
    --raw(-r)
] {
    let md = curl -sSL ...$args
    | ^($env.HTML_TO_MARKDOWN? | default 'html2markdown')

    let content = if ($transform | is-not-empty) {
        $md | do $transform
    } else if 'MARKDOWN_TRANSFORM' in $env {
        $md | do $env.MARKDOWN_TRANSFORM
    } else {
        $md
    }

    if $raw {
        $content
    } else {
        $content | ^($env.MARKDOWN_RENDER? | default 'glow')
    }
}

