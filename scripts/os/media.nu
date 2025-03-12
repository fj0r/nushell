export def screenshot [file?: path] {
    let a = if ($file | is-empty) {
        mktemp -t XXX.png
    } else {
        $file
    }
    grim -g $"(slurp)" - | save $a
    $a
}

export def screen_record [file?: path] {
    let a = if ($file | is-empty) {
        mktemp -t XXX.webm
    } else {
        $file
    }
    ffmpeg -s 1920x1080 -i - -c:v libx264 -f webm -preset ultrafast output.webm
}

export def audio_record [file?: path] {
    let a = if ($file | is-empty) {
        mktemp -t XXX.mp3
    } else {
        $file
    }
    print $"(ansi grey)Recording started. Please speak clearly into the microphone. Press [(ansi yellow)q(ansi grey)] when finished.(ansi reset)"
    let inputfmt = match $nu.os-info.name {
        linux => 'alsa'
        windows => 'lavfi'
        _ => 'avfoundation'
    }
    ffmpeg -f $inputfmt -y -loglevel error -i default -acodec libmp3lame -ar 44100 -ac 2 $a
    $a
}
