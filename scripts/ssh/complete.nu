export def cmpl-ssh [] {
    run "select name from ssh" | get name
}

