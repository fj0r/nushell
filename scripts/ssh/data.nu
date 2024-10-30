use common.nu *

export def --env start [] {
    if 'SSH_DB' not-in $env {
        $env.SSH_DB = [$nu.data-dir 'ssh.db'] | path join
    }
    if 'SSH_ENV' not-in $env {
        $env.SSH_ENV = 'default'
    }
    if ($env.SSH_DB | path exists) { return }
    {_: '.'} | into sqlite -t _ $env.SSH_DB
    print $"(ansi grey)created database: $env.SSH_DB(ansi reset)"
    for s in [
        "DROP TABLE _;"
        "CREATE TABLE IF NOT EXISTS env (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT DEFAULT ''
        );"
        "INSERT into env (name) values ('default');"
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
            permanent TEXT DEFAULT '', -- 'config.d/git'
            options TEXT DEFAULT '',
            created TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            updated TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
            deleted TEXT DEFAULT ''
        );"
        "CREATE TABLE IF NOT EXISTS ssh_key (
            env_id INTEGER NOT NULL,
            ssh_name TEXT NOT NULL,
            key_name TEXT NOT NULL,
            PRIMARY KEY (env_id, ssh_name, key_name)
        );"
        "CREATE TABLE IF NOT EXISTS ssh_host (
            env_id INTEGER NOT NULL,
            ssh_name TEXT NOT NULL,
            host_name TEXT NOT NULL,
            PRIMARY KEY (env_id, ssh_name, host_name)
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
