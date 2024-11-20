export def cmpl-ssh [] {
    sqlx "select name from ssh" | get name
}

