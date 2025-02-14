export def ascii-rec [
    name
    --target(-t): path = '~/Pictures'
    --gif
] {
    let file = [$target asciinema $name] | path join | path expand
    $env.ASCIINEMA_ID = $name
    asciinema rec --overwrite $"($file).cast"

    if ([y n] | input list $'(ansi grey)upload ($file).cast?(ansi reset)') == 'y' {
        asciinema upload $"($file).cast"
    }
    if $gif and ([y n] | input list $'(ansi grey)convert ($file).cast to gif?(ansi reset)') == 'y' {
        agg $"($file).cast" $"($file).gif"
    }
}
