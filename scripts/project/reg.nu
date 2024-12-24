def --env init-db [env_name:string, file:string, hook: closure] {
    let begin = date now
    if $env_name not-in $env {
        {$env_name: $file} | load-env
    }
    if ($file | path exists) { return }
    {_: '.'} | into sqlite -t _ $file
    open $file | query db "DROP TABLE _;"
    do $hook {|s| open $file | query db $s }
    print $"(ansi grey)created database: $env.($env_name), takes ((date now) - $begin)(ansi reset)"
}

def cmpl-dir [] {
    sqlx "select dir as value, group_concat(command, ' | ') as description
        from dirs join commands on id = dir_id group by dir;"
}

def cmpl-cmd [ctx] {
    let dir = $ctx | argx parse --pos | get pos.dir
    sqlx $"select command from dirs join commands on id = dir_id where dir = (Q $dir)" | get command
}

export def 'project exec' [
    dir:string@cmpl-dir
    ...cmd:string@cmpl-cmd
    --prefix:string='__'
    --mods(-m): list<string>
] {
    cd $dir
    let mods = if ($mods | is-empty) {
        sqlx $"select mod from mods join dirs on id = dir_id where dir = (Q $dir)"
        | get mod
    } else {
        let ms = $mods | each { $"\((Q $in)\)" } | str join ','
        let stmt = $"with x\(mod\) as \(VALUES ($ms)\)
            , r as \(select id as dir_id, mod from dirs, x where dir = (Q $dir)\)
            insert or replace into mods select * from r"
        sqlx $stmt
        $mods
    }
    | each { $"use ($in)" }

    let cmd = [
        'use project'
        ...$mods
        'project direnv __'
        'overlay use -r __.nu as __ -p'
        $'__ ($cmd | str join " ")'
    ]
    | str join '; '

    nu -c $cmd
}

export def Q [...t --sep:string=''] {
    let s = $t | str join $sep | str replace -a "'" "''"
    $"'($s)'"
}

export def sqlx [s] {
    open $env.PROJECT_STATE | query db $s
}

export def --env 'project register' [
    --mod:string='__'
    dir?:string
] {
    let dir = if ($dir | is-empty) { $env.PWD } else { $dir }

    init-db PROJECT_STATE ([$nu.data-dir 'project.db'] | path join) {|sqlx|
        for s in [
            "CREATE TABLE IF NOT EXISTS dirs (
                id INTEGER PRIMARY KEY,
                dir TEXT NOT NULL UNIQUE
            );"
            "CREATE TABLE IF NOT EXISTS commands (
                dir_id INTEGER NOT NULL,
                command TEXT NOT NULL,
                created TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
                PRIMARY KEY (dir_id, command)
            );"
            "CREATE TABLE IF NOT EXISTS mods (
                dir_id INTEGER NOT NULL,
                mod TEXT NOT NULL,
                PRIMARY KEY (dir_id, mod)
            );"
        ] {
            do $sqlx $s
        }
    }

    let dir_id = sqlx $"insert into dirs \(dir\) values \((Q $dir)\)
        on conflict \(dir\) do update set dir = EXCLUDED.dir returning id;
    " | get 0.id
    let cmds = scope modules | where name == $mod | first | get commands.name
    | each { $"\(($dir_id), (Q $in)\)" } | str join ', '
    sqlx $"insert into commands \(dir_id, command\) values ($cmds)
        on conflict \(dir_id, command\) do nothing"
}

export def 'project unregister' [
    --dir:string
] {
    let dir = if ($dir | is-empty) { $env.PWD } else { $dir }
    sqlx $"delete from commands where dir_id in \(select id from dirs where dir = (Q $dir)\);"
}

