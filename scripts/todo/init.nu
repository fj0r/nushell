use completion.nu *
use common.nu *


export def --env start [] {
    let db = [$nu.data-dir '2do.db'] | path join
    $env.TODO_DB = $db
    if ($env.TODO_DB | path exists) { return }
    {_: '.'} | into sqlite -t _ $env.TODO_DB
    for s in [
        "CREATE TABLE IF NOT EXISTS category (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL UNIQUE
        );"
        "CREATE TABLE IF NOT EXISTS tag (
            id INTEGER PRIMARY KEY,
            category_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            UNIQUE (category_id, name) ON CONFLICT REPLACE
        );"
        "INSERT INTO category (id, name) VALUES (1, '');"
        "INSERT INTO tag (category_id, name) VALUES (1, 'trash');"
        "CREATE TABLE IF NOT EXISTS todo (
            id INTEGER PRIMARY KEY,
            parent_id INTEGER DEFAULT -1,
            title TEXT NOT NULL,
            description TEXT DEFAULT '',
            created TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            updated TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            deadline TEXT,
            important INTEGER DEFAULT -1,
            urgent INTEGER DEFAULT -1,
            challenge INTEGER DEFAULT -1,
            delegate TEXT DEFAULT '',
            done BOOLEAN DEFAULT -1
        );"
        "CREATE TABLE IF NOT EXISTS todo_tag (
            todo_id INTEGER NOT NULL,
            tag_id INTEGER NOT NULL,
            PRIMARY KEY (todo_id, tag_id)
        );"
    ] {
        open $env.TODO_DB | query db $s
    }
}
