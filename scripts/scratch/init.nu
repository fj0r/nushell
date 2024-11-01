use common.nu *


export def --env start [] {
    if 'SCRATCH_DB' not-in $env {
        $env.SCRATCH_DB = [$nu.data-dir 'scratch.db'] | path join
    }
    if ($env.SCRATCH_DB | path exists) { return }
    {_: '.'} | into sqlite -t _ $env.SCRATCH_DB
    print $"(ansi grey)created database: $env.SCRATCH_DB(ansi reset)"
    for s in [
        "DROP TABLE _;"
        "CREATE TABLE IF NOT EXISTS tag (
            id INTEGER PRIMARY KEY,
            parent_id INTEGER DEFAULT -1,
            name TEXT NOT NULL,
            hidden BOOLEAN DEFAULT 0
        );"
        "CREATE TABLE IF NOT EXISTS scratch (
            id INTEGER PRIMARY KEY,
            parent_id INTEGER DEFAULT -1,
            title TEXT NOT NULL,
            type TEXT DEFAULT '',
            content TEXT DEFAULT '',
            created TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            updated TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            deleted TEXT DEFAULT '',
            important INTEGER DEFAULT -1,
            urgent INTEGER DEFAULT -1,
            challenge INTEGER DEFAULT -1
        );"
        "CREATE TABLE IF NOT EXISTS scratch_tag (
            scratch_id INTEGER NOT NULL,
            tag_id INTEGER NOT NULL,
            PRIMARY KEY (scratch_id, tag_id)
        );"
        "CREATE TABLE IF NOT EXISTS type (
            name TEXT PRIMARY KEY,
            comment TEXT DEFAULT '#',
            runner TEXT NOT NULL DEFAULT 'none', -- file, dir, remote
            created TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            updated TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            deleted TEXT DEFAULT ''
        );"
    ] {
        run $s
    }
    "
    - name: md
      comment: '# '
      runner: 'none'
    - name: nu
      comment: '# '
      runner: file
    - name: py
      comment: '# '
      runner: file
    - name: js
      comment: '// '
      runner: file
    - name: ts
      comment: '// '
      runner: file
    - name: rs
      comment: '// '
      runner: dir
    - name: hs
      comment: '-- '
      runner: dir
    - name: lua
      comment: '-- '
      runner: file
    - name: pg
      comment: '-- '
      runner: remote
    "
    | from yaml | each { $in | add-type }
}
