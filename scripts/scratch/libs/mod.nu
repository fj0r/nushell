export use edit.nu *
export use db.nu *
export use str.nu *
export use time.nu *
export use exec.nu *


export def get-config [kind] {
    sqlx $"select * from kind where name = (Q $kind)" | first
}

export def 'to title' [config] {
    $in | str replace ($config.comment) ''
}

export def 'from title' [config] {
    $"($config.comment)($in)"
}

