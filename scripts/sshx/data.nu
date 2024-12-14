use common.nu *
use parse.nu *

export def Q [...t --sep:string=''] {
    let s = $t | str join $sep | str replace -a "'" "''"
    $"'($s)'"
}

export def sqlx [s] {
    open $env.SSH_STATE | query db $s
}

export def --env init-db [env_name:string, file:string, hook: closure] {
    let begin = date now
    if $env_name not-in $env {
        {$env_name: $file} | load-env
    }
    if ($file | path exists) { return }
    {_: '.'} | into sqlite -t _ $file
    open $file | query db "DROP TABLE _;"
    do $hook {|s| open $file | query db $s } {|...t| Q ...$t }
    print $"(ansi grey)created database: $env.($env_name), takes ((date now) - $begin)(ansi reset)"
}

export def seed [] {

}

export def --env start [] {
    init-db SSH_STATE ([$nu.data-dir 'ssh.db'] | path join) {|sqlx, Q|
        for s in [
            "CREATE TABLE IF NOT EXISTS env (
                name TEXT PRIMARY KEY,
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
                address TEXT NOT NULL,
                port TEXT NOT NULL DEFAULT '22',
                type TEXT DEFAULT 'linux',
                description TEXT DEFAULT '',
                created TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
                updated TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
                deleted TEXT DEFAULT ''
            );"
            "CREATE TABLE IF NOT EXISTS ssh (
                name TEXT PRIMARY KEY,
                permanent TEXT DEFAULT '', -- 'config.d/git'
                options TEXT DEFAULT '',
                created TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
                updated TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
                deleted TEXT DEFAULT ''
            );"
            "CREATE TABLE IF NOT EXISTS ssh_key (
                env_name TEXT NOT NULL,
                user TEXT NOT NULL DEFAULT 'root',
                ssh_name TEXT NOT NULL,
                key_name TEXT NOT NULL,
                PRIMARY KEY (env_name, ssh_name, key_name)
            );"
            "CREATE TABLE IF NOT EXISTS ssh_host (
                env_name TEXT NOT NULL,
                ssh_name TEXT NOT NULL,
                host_name TEXT NOT NULL,
                PRIMARY KEY (env_name, ssh_name, host_name)
            );"
            "CREATE TABLE IF NOT EXISTS ssh_forward (
                ssh_name TEXT NOT NULL,
                local TEXT NOT NULL,
                remote TEXT NOT NULL,
                type TEXT NOT NULL,
                PRIMARY KEY (ssh_name, local, remote, type)
            );"
            "CREATE TABLE IF NOT EXISTS ssh_sync (
                ssh_name TEXT NOT NULL,
                local TEXT NOT NULL,
                remote TEXT NOT NULL,
                type TEXT NOT NULL,
                PRIMARY KEY (ssh_name, local, remote, type)
            );"
            "CREATE TABLE IF NOT EXISTS ssh_tag (
                ssh_name TEXT NOT NULL,
                tag_id INTEGER NOT NULL,
                PRIMARY KEY (ssh_name, tag_id)
            );"
        ] {
            do $sqlx $s
        }
        seed
    }
}

export def load [] {
    for s in (ssh-list) {
        print $s
        let tag = $s.Group | split row '/' | last
        let tag_id = sqlx $"select id from tag where name = (Q $tag)"
        let tag_id = if ($tag_id | is-empty) {
            sqlx $"insert into tag \(name\) values \((Q $tag)\) returning id"
        } else {
            $tag_id
        } | get 0.id
        let name = Q $s.Host
        let user = Q ($s.User? | default 'root')
        let addr = Q $s.HostName
        let port = Q ($s.Port? | default '22')
        let keyname = $s.IdentityFile | split row '/' | last
        let pubkey = if ($"($s.IdentityFile).pub" | path exists) { open $"($s.IdentityFile).pub" }
        let prikey = open $s.IdentityFile
        sqlx $"insert into key \(name, type, public_key, private_key\) values \((Q $keyname), 'ed25519', ($pubkey), ($prikey)\)"
        sqlx $"insert into host \(name, address, port\) values \(($name), ($addr), ($port)\)"
        sqlx $"insert into ssh \(
            name
        \) values \(
            ($name)
        \);"
        sqlx $"insert into ssh_host \(env_name, ssh_name, host_name\) values \('default', ($name), ($name)\)"
        sqlx $"insert into ssh_key \(env_name, user, ssh_name, key_name\) values \('default', ($user), ($name), ($name)\)"
        sqlx $"insert into ssh_tag \(ssh_name, tag_id\) values \(($name), ($tag_id)\)"
    }
}
