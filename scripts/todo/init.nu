use completion.nu *
use common.nu *


export def --env start [] {
    let db = [$nu.data-dir '2do.db'] | path join
    $env.TODO_DB = $db
    if ($env.TODO_DB | path exists) { return }
    {_: '.'} | into sqlite -t _ $env.TODO_DB
    print $"(ansi grey)created database: $env.TODO_DB(ansi reset)"
    for s in [
        "DROP TABLE _;"
        "CREATE TABLE IF NOT EXISTS category (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            hidden BOOLEAN DEFAULT 0
        );"
        "CREATE TABLE IF NOT EXISTS tag (
            id INTEGER PRIMARY KEY,
            category_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            UNIQUE (category_id, name) ON CONFLICT REPLACE
        );"
        "INSERT INTO category (id, name, hidden) VALUES (1, '', 1);"
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
            value REAL DEFAULT 0,
            done BOOLEAN DEFAULT -1,
            delegate TEXT DEFAULT ''
        );"
        "CREATE TABLE IF NOT EXISTS todo_tag (
            todo_id INTEGER NOT NULL,
            tag_id INTEGER NOT NULL,
            PRIMARY KEY (todo_id, tag_id)
        );"
        "CREATE TABLE IF NOT EXISTS scratch (
            id INTEGER PRIMARY KEY,
            parent_id INTEGER DEFAULT -1,
            title TEXT NOT NULL,
            type TEXT DEFAULT '',
            content TEXT DEFAULT '',
            created TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            updated TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            important INTEGER DEFAULT -1,
            urgent INTEGER DEFAULT -1,
            challenge INTEGER DEFAULT -1
        );"
        "CREATE TABLE IF NOT EXISTS scratch_tag (
            scratch_id INTEGER NOT NULL,
            tag_id INTEGER NOT NULL,
            PRIMARY KEY (scratch_id, tag_id)
        );"
    ] {
        open $env.TODO_DB | query db $s
    }
}

export def --env theme [] {
    $env.TODO_THEME = {
        color: {
            title: default
            id: xterm_grey39
            cat: xterm_lightslategrey
            tag: xterm_wheat4
            important: yellow
            urgent: red
            challenge: blue
            deadline: xterm_rosybrown
            created: xterm_paleturquoise4
            updated: xterm_lightsalmon3a
            description: grey
        }
        symbol: {
            box: [['☐' '🗹'],['[ ]' '[x]']]
        }
        formatter: {
            created: {|x| $x | into datetime | date humanize }
            updated: {|x| $x | into datetime | date humanize }
            deadline: {|x, o|
                let t = $x | into datetime
                let s = $t | date humanize
                if ($t - (date now) | into int) > 0 { $s } else { $"!($s)" }
            }
            important: {|x| '' | fill -c '☆ ' -w $x }
            urgent: {|x| '' | fill -c '🔥' -w $x }
            challenge: {|x| '' | fill -c '⚡' -w $x }
        }

    }
}
