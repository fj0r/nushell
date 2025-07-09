export-env {
    $env.HISTORY_BACKUP_DIR = $'($env.HOME)/.cache/nu-history-backup'
}

# (Destroy the results of `history top`)
export def 'history deduplicate' [] {
    "with b as (
        select id from history group by command_line order by start_timestamp desc
    ), x as (
        select a.id from history as a left join b on a.id = b.id where b.id is null
    ) delete from history where id in x;
    "
    | sqlite3 $nu.history-path
}

# backup history
export def 'history backup' [tag?] {
    if (which sqlite3 | is-empty) {
        print -e $'(ansi light_gray)please install sqlite3(ansi reset)'
        return
    }
    mkdir $env.HISTORY_BACKUP_DIR
    let tag = if ($tag | is-empty) { '' } else { $"($tag)::" }
    [
        $".output ($env.HISTORY_BACKUP_DIR)/($tag)(date now | format date "%y_%m_%d_%H_%M_%S").sql"
        $"update history set cwd = replace\(cwd, '($env.HOME)', '~');"
        '.dump'
        $"update history set cwd = replace\(cwd, '~', '($env.HOME)');"
        '.quit'
    ]
    | str join (char newline)
    | sqlite3 $nu.history-path
}

def cmpl-history_backup_file [] {
    let c = ls $env.HISTORY_BACKUP_DIR | each {|x| $x.name | path parse } | get stem | reverse
    { completions: $c, options: { sort: false } }
}
# restore history
export def 'history restore' [name: string@cmpl-history_backup_file] {
    if (which sqlite3 | is-empty) {
        print -e $'(ansi light_gray)please install sqlite3(ansi reset)'
        return
    }
    rm -f $nu.history-path
    open ([$env.HISTORY_BACKUP_DIR, $"($name).sql"] | path join)
    | sqlite3 $nu.history-path
    [
        $"update history set cwd = replace\(cwd, '~', '($env.HOME)');"
        '.quit'
    ]
    | str join (char newline)
    | sqlite3 $nu.history-path
}
