export def watch-clip [act] {
    wl-paste -w cat | each { $in | do $act; print "\n" }
}
