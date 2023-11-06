export def 'config update' [ ] {
    cd ($nu.config-path | path dirname)
    git pull
    #git log -1 --date=iso
    #source '($nu.config-path)'
}

def "nu-complete config scripts" [] {
    ls -s ([($nu.config-path | path dirname) scripts '*.nu'] | path join)
    | each {|x| $x.name | str substring ..-3 }
}

export def 'config edit' [script: string@"nu-complete config scripts"] {
    let f = ([($nu.config-path | path dirname) scripts $'($script).nu'] | path join)
    e $f
}

def "nu-complete config table-modes" [] {
    [basic, compact, compact_double, light, thin, with_love, rounded, reinforced, heavy, none, other]
}

export def --env 'config table mode' [mode: string@"nu-complete config table-modes"] {
    $env.config.table.padding = 1
    $env.config.table.mode = $mode
}

export def 'config reset' [] {
    config nu --default | save -f $nu.config-path
    echo $"(char newline)source __env.nu" | save -a $nu.config-path
    echo $"(char newline)source __config.nu" | save -a $nu.config-path
    config env --default | save -f $nu.env-path
}


export-env {
    $env.history_backup_dir = $'($env.HOME)/.cache/nu-history-backup'
}
# backup history
export def 'history backup' [] {
    ^mkdir [-p $env.history_backup_dir]
    $'.output ($env.history_backup_dir)/(date now | format date "%y%m%d%H%M%S").sql
    (char newline).dump
    (char newline).quit' | sqlite3 $nu.history-path
}

def "nu-complete history_backup_file" [] {
    ls $env.history_backup_dir | each {|x| $x.name | path parse } | get stem | reverse
}
# restore history
export def 'history restore' [name: string@"nu-complete history_backup_file"] {
    rm -f $nu.history-path
    cat ([$env.history_backup_dir, $"($name).sql"] | path join) | sqlite3 $nu.history-path
}
