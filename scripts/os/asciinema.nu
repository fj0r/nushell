export def ascii-rec [
    name
    --target(-t): path = '~/Downloads'
] {
    let file = [$target $name] | path join | path expand
    asciinema rec --overwrite $"($file).cast"
    if ([y n] | input list $'(ansi grey)convert ($file).cast to gif?(ansi reset)') == 'y' {
        agg $"($file).cast" $"($file).gif"
    }
}
