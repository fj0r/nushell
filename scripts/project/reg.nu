export-env {
    if 'config' in $env {
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

        init-db PROJECT_STATE ([$nu.data-dir 'project.db'] | path join) {|sqlx|
            do $sqlx "
                CREATE TABLE IF NOT EXISTS commands (
                    dir TEXT NOT NULL,
                    command INTEGER NOT NULL,
                    created TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
                    PRIMARY KEY (dir, command)
                );"
        }
    }
}

def cmpl-dir [] {
    sqlx "select dir as value, group_concat(command, ' | ') as description
        from commands group by dir;"
}

def cmpl-cmd [ctx] {
    let dir = $ctx | argx parse --pos | get pos.dir
    sqlx $"select command from commands where dir = (Q $dir)" | get command
}

export def 'project exec' [
    dir:string@cmpl-dir
    ...cmd:string@cmpl-cmd
    --mod:string='__'
] {
    cd $dir
    [
        'use project'
        'project direnv __'
        'overlay use -r __.nu as __ -p'
        $'__ ($cmd | str join " ")'
    ]
    | str join '; '
    | nu -c $in
}

export def Q [...t --sep:string=''] {
    let s = $t | str join $sep | str replace -a "'" "''"
    $"'($s)'"
}

export def sqlx [s] {
    open $env.PROJECT_STATE | query db $s
}

export def 'project register' [
    --mod:string='__'
    dir?:string
] {
    let dir = if ($dir | is-empty) { $env.PWD } else { $dir }
    let cmds = scope modules | where name == $mod | first | get commands.name
    | each { $"\((Q $dir), (Q $in)\)" } | str join ', '
    sqlx $"insert into commands \(dir, command\) values ($cmds)
        on conflict \(dir, command\) do nothing"
}

export def 'project unregister' [
    --dir:string
] {
    let dir = if ($dir | is-empty) { $env.PWD } else { $dir }
    sqlx $"delete from commands where dir = (Q $dir)"
}

