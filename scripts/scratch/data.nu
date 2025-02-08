use libs *
use common.nu *
use libs/files.nu *

export def seed [] {
    const dir = path self .

    ls ([$dir data kind] | path join) | get name | each { open $in | upsert-kind }
    ls ([$dir data preset] | path join) | get name | each { open $in | upsert-kind-preset }
    ls ([$dir data files] | path join) | get name | each {
        open $in | each { scratch-files-import $in }
    }
}

export def --env init [] {
    init-db SCRATCH_STATE ([$nu.data-dir 'scratch.db'] | path join) {|sqlx, Q|
        for s in [
            "CREATE TABLE IF NOT EXISTS person (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL UNIQUE,
                info TEXT default ''
            );"
            "CREATE TABLE IF NOT EXISTS tag (
                id INTEGER PRIMARY KEY,
                parent_id INTEGER DEFAULT -1,
                name TEXT NOT NULL,
                alias TEXT NOT NULL DEFAULT '',
                hidden BOOLEAN DEFAULT 0,
                UNIQUE(parent_id, name)
            );"
            "CREATE TABLE IF NOT EXISTS scratch (
                id INTEGER PRIMARY KEY,
                parent_id INTEGER DEFAULT -1,
                kind TEXT DEFAULT '',
                title TEXT NOT NULL DEFAULT '',
                body TEXT DEFAULT '',
                created TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%f','now')),
                updated TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%f','now')),
                deleted TEXT DEFAULT '',
                deadline TEXT,
                important INTEGER DEFAULT -1,
                urgent INTEGER DEFAULT -1,
                challenge INTEGER DEFAULT -1,
                value REAL DEFAULT 0,
                done BOOLEAN DEFAULT 0,
                relevant INTEGER -- REFERENCES person(id)
            );"
            "CREATE TABLE IF NOT EXISTS scratch_tag (
                scratch_id INTEGER NOT NULL,
                tag_id INTEGER NOT NULL,
                PRIMARY KEY (scratch_id, tag_id)
            );"
            "CREATE TABLE IF NOT EXISTS kind (
                name TEXT PRIMARY KEY,
                entry TEXT NOT NULL,
                comment TEXT NOT NULL DEFAULT '# ',
                runner TEXT NOT NULL DEFAULT '',
                cmd TEXT NOT NULL DEFAULT '',
                pos INTEGER NOT NULL DEFAULT 1,
                created TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
                updated TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
                deleted TEXT DEFAULT ''
            );"
            "CREATE TABLE IF NOT EXISTS kind_preset (
                kind TEXT NOT NULL,
                name TEXT NOT NULL,
                data TEXT NOT NULL DEFAULT '',
                PRIMARY KEY (kind, name)
            );"
            "CREATE TABLE IF NOT EXISTS scratch_preset (
                scratch_id INTEGER NOT NULL,
                preset TEXT NOT NULL,
                PRIMARY KEY (scratch_id)
            );"
            "CREATE TABLE IF NOT EXISTS kind_file (
                kind TEXT NOT NULL,
                parent TEXT NOT NULL DEFAULT '.',
                stem TEXT NOT NULL,
                extension TEXT NOT NULL,
                hash TEXT NOT NULL,
                PRIMARY KEY (kind, parent, stem, extension)
            );"
            "CREATE TABLE IF NOT EXISTS file (
                hash TEXT PRIMARY KEY,
                body TEXT NOT NULL DEFAULT ''
            );"
        ] {
            do $sqlx $s
        }
        seed
    }
}


export def --env theme [] {
    $env.SCRATCH_THEME = {
        color: {
            title: default
            id: xterm_grey39
            value: {
                positive: xterm_green
                negative: xterm_red
            }
            tag: xterm_wheat4
            important: yellow
            urgent: red
            challenge: blue
            deadline: xterm_rosybrown
            created: xterm_paleturquoise4
            updated: xterm_lightsalmon3a
            body: grey
            branch: xterm_wheat1
        }
        symbol: {
            box: [['☐' '🗹' '☒' '*'],['[ ]' '[x]' '[-]' '']]
            md_list: '-'
        }
        formatter: {
            created: {|x| $x | into datetime | date humanize }
            updated: {|x| $x | into datetime | date humanize }
            deadline: {|x, o|
                let t = $x | into datetime
                let s = $t | date humanize
                if ($t - (date now) | into int) > 0 { $s } else { $"(ansi purple_reverse)($s)(ansi reset)" }
            }
            important: {|x| '' | fill -c '☆ ' -w $x }
            urgent: {|x| '' | fill -c '🔥' -w $x }
            challenge: {|x| '' | fill -c '⚡' -w $x }
        }
    }
    $env.SCRATCH_ACCUMULATOR = {
        sum: {
            sum: [{ $in.value | math sum }, { $in | math sum }]
        }
        done: {
            done: [{ $in.done | filter { $in == 1 } | length }, { $in | math sum }]
        }
        count: {
            count: [{ $in | length }, { $in | math sum }]
        }
    }
}
