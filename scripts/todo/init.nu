use completion.nu *
use common.nu *


export def --env start [] {
    if 'TODO_DB' not-in $env {
        $env.TODO_DB = [$nu.data-dir 'todo.db'] | path join
    }
    if ($env.TODO_DB | path exists) { return }
    {_: '.'} | into sqlite -t _ $env.TODO_DB
    print $"(ansi grey)created database: $env.TODO_DB(ansi reset)"
    for s in [
        "DROP TABLE _;"
        "CREATE TABLE IF NOT EXISTS tag (
            id INTEGER PRIMARY KEY,
            parent_id INTEGER DEFAULT -1,
            name TEXT NOT NULL,
            hidden BOOLEAN DEFAULT 0,
            UNIQUE(parent_id, name)
        );"
        "CREATE TABLE IF NOT EXISTS person (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            info TEXT default ''
        );"
        "CREATE TABLE IF NOT EXISTS todo (
            id INTEGER PRIMARY KEY,
            parent_id INTEGER DEFAULT -1,
            title TEXT NOT NULL,
            content TEXT DEFAULT '',
            created TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            updated TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            deleted TEXT DEFAULT '',
            deadline TEXT,
            important INTEGER DEFAULT -1,
            urgent INTEGER DEFAULT -1,
            challenge INTEGER DEFAULT -1,
            value REAL DEFAULT 0,
            done BOOLEAN DEFAULT -1,
            relevant INTEGER REFERENCES person(id)
        );"
        "CREATE TABLE IF NOT EXISTS todo_tag (
            todo_id INTEGER NOT NULL,
            tag_id INTEGER NOT NULL,
            PRIMARY KEY (todo_id, tag_id)
        );"
    ] {
        run $s
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
            content: grey
        }
        symbol: {
            box: [['☐' '🗹' '*'],['[ ]' '[x]' '']]
            md_list: '-'
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
