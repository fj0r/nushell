export def --wrapped 'mdurl' [...args --transform(-t): closure] {
    curl -sSL ...$args
    | ^($env.HTML_TO_MARKDOWN? | default 'html2markdown')
    | if ($transform | is-empty) { $in } else { $in | do $transform }
    | ^($env.MARKDOWN_RENDER? | default 'mdcat')
}
