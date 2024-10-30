use common.nu *

export def --env start [] {
    if 'SSH_DB' not-in $env {
        $env.SSH_DB = [$nu.data-dir 'ssh.db'] | path join
    }
    if ($env.SSH_DB | path exists) { return }
    {_: '.'} | into sqlite -t _ $env.SSH_DB
    print $"(ansi grey)created database: $env.SSH_DB(ansi reset)"
    for s in [
        "DROP TABLE _;"
        "CREATE TABLE IF NOT EXISTS tag (
            id INTEGER PRIMARY KEY,
            parent_id INTEGER DEFAULT -1,
            name TEXT NOT NULL,
            hidden BOOLEAN DEFAULT 0
        );"
        "CREATE TABLE IF NOT EXISTS key (
            name TEXT PRIMARY KEY,
            type TEXT DEFAULT 'ed25519',
            public_key TEXT DEFAULT '',
            private_key TEXT DEFAULT '',
            created TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            updated TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            deleted TEXT DEFAULT ''
        );"
        "CREATE TABLE IF NOT EXISTS host (
            name TEXT PRIMARY KEY,
            type TEXT DEFAULT 'linux',
            description TEXT DEFAULT '',
            created TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            updated TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            deleted TEXT DEFAULT ''
        );"
        "CREATE TABLE IF NOT EXISTS ssh (
            name TEXT PRIMARY KEY,
            user TEXT NOT NULL DEFAULT 'root',
            created TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            updated TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            deleted TEXT DEFAULT ''
        );"
        "CREATE TABLE IF NOT EXISTS ssh_key (
            ssh_name TEXT NOT NULL,
            key_name TEXT NOT NULL,
            PRIMARY KEY (ssh_name, key_name)
        );"
        "CREATE TABLE IF NOT EXISTS ssh_host (
            ssh_name TEXT NOT NULL,
            host_name TEXT NOT NULL,
            PRIMARY KEY (ssh_name, host_name)
        );"
        "CREATE TABLE IF NOT EXISTS ssh_tag (
            ssh_name TEXT NOT NULL,
            tag_id INTEGER NOT NULL,
            PRIMARY KEY (ssh_name, tag_id)
        );"
    ] {
        run $s
    }
}
