export def screenshot [] {
    let dist = [$env.HOME Pictures Screenshots $"Screenshot-(date now | format date '%F_%H:%M:%S').png"] | path join
    grim -g $"(slurp)" - | save $dist
    dunstify $"Screenshot of the region taken" -t 1000
}

export def screencapture [] {
    ffmpeg -s 1920x1080 -i - -c:v libx264 -f webm -preset ultrafast output.webm
}

export def audio_record [] {
    let a = mktemp -t XXX.mp3
    print $"(ansi grey)Recording started. Please speak clearly into the microphone. Press [(ansi yellow)q(ansi grey)] when finished.(ansi reset)"
    let inputfmt = match $nu.os-info.name {
        linux => 'alsa'
        windows => 'dshow'
        _ => 'avfoundation'
    }
    ffmpeg -f $inputfmt -y -loglevel error -i default -acodec libmp3lame -ar 44100 -ac 2 $a
    $a
}
