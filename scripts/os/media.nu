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
    let r = slurp | split row ' '
    let s = $r.0 | split row ','
    (
    ffmpeg -y -loglevel error
        -f gdigrab -i desktop
        -show_mouse 1
        -offset_x $s.0 -offset_y $s.1 -video_size $r.1
        -c:v libx264
        $a
    )
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
    (
    ffmpeg -y -loglevel error
        -f $inputfmt
        -i default
        -acodec libmp3lame
        -ar 44100 -ac 2
        $a
    )
    $a
}
