export def screenshot [] {
    let dist = [$env.HOME Pictures Screenshots $"Screenshot-(date now | format date '%F_%H:%M:%S').png"] | path join
    grim -g $"(slurp)" - | save $dist
    dunstify $"Screenshot of the region taken" -t 1000
}

export def screencapture [] {
    ffmpeg -s 1920x1080 -i - -c:v libx264 -f webm -preset ultrafast output.webm
}
