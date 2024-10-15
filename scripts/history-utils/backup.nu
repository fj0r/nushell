export-env {
    $env.history_backup_dir = $'($env.HOME)/.cache/nu-history-backup'
}

# backup history
export def 'history backup' [tag?] {
    if (which sqlite3 | is-empty) {
        print -e $'(ansi light_gray)please install sqlite3(ansi reset)'
        return
    }
    mkdir $env.history_backup_dir
    let tag = if ($tag | is-empty) { '' } else { $"($tag)::" }
    [
        $".output ($env.history_backup_dir)/($tag)(date now | format date "%y_%m_%d_%H_%M_%S").sql"
        $"update history set cwd = replace\(cwd, '($env.HOME)', '~');"
        '.dump'
        $"update history set cwd = replace\(cwd, '~', '($env.HOME)');"
        '.quit'
    ]
    | str join (char newline)
    | sqlite3 $nu.history-path
}

def cmpl-history_backup_file [] {
    ls $env.history_backup_dir | each {|x| $x.name | path parse } | get stem | reverse
}
# restore history
export def 'history restore' [name: string@cmpl-history_backup_file] {
    if (which sqlite3 | is-empty) {
        print -e $'(ansi light_gray)please install sqlite3(ansi reset)'
        return
    }
    rm -f $nu.history-path
    open ([$env.history_backup_dir, $"($name).sql"] | path join)
    | sqlite3 $nu.history-path
    [
        $"update history set cwd = replace\(cwd, '~', '($env.HOME)');"
        '.quit'
    ]
    | str join (char newline)
    | sqlite3 $nu.history-path
}
