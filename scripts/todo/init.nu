use completion.nu *
use common.nu *


export def --env start [] {
    let db = [$nu.data-dir 'todo.db'] | path join
    $env.TODO_DB = $db
    if ($env.TODO_DB | path exists) { return }
    {_: '.'} | into sqlite -t _ $env.TODO_DB
    for s in [
        "CREATE TABLE IF NOT EXISTS tags (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL UNIQUE
        );"
        "CREATE TABLE IF NOT EXISTS todo (
            id INTEGER PRIMARY KEY,
            parent_id INTEGER DEFAULT 0,
            title TEXT NOT NULL,
            description TEXT DEFAULT '',
            created TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            updated TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            deadline TEXT,
            important INTEGER DEFAULT 0,
            urgent INTEGER DEFAULT 0,
            delegate TEXT DEFAULT '',
            done BOOLEAN DEFAULT 0
        );"
        "CREATE TABLE IF NOT EXISTS todo_tags (
            todo_id INTEGER,
            tag_id INTEGER
        );"
    ] {
        open $env.TODO_DB | query db $s
    }
}
