export def Q [...t] {
    let s = $t | str join '' | str replace -a "'" "''"
    $"'($s)'"
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

export def sqlx [stmt] {
    open $env.ATOM_STATE | query db $stmt
}

export def db-upsert [table pk --do-nothing] {
    let r = $in
    let d = if $do_nothing { 'NOTHING' } else {
        let u = $r | columns | each {|x| $"($x) = EXCLUDED.($x)" } | str join ', '
        $"UPDATE SET ($u)"
    }
    let q = $"INSERT INTO ($table)\(($r | columns | str join ',')\)
            VALUES\(($r | values | each {Q $in} | str join ',')\)
            ON CONFLICT\(($pk | str join ', ')\) DO ($d);"
    sqlx $q
}

export def table-merge [
    config
    --action: closure
] {
    let d = $in
    let d = $config.default | merge $d
    let d = if ($action | is-not-empty) {
        $d | do $action $config
    } else {
        $d
    }
    $d | select ...($config.default | columns)
}

export def table-upsert [
    config
    --delete
    --action: closure
] {
    let r = $in
    | table-merge $config --action $action
    if $delete {
        let pks = $config.default
        | columns
        | reduce -f {} {|i,a|
            if $i in $config.pk {
                $a | insert $i ($r | get $i)
            } else {
                $a
            }
        }
        | items {|k,v|
            $"($k) = (Q $v)"
        }
        | str join ' and '
        sqlx $"delete from ($config.table) where ($pks)"
    } else {
        $r | db-upsert $config.table $config.pk
    }
}
