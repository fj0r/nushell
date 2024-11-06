export def Q [...t] {
    let s = $t | str join '' | str replace -a "'" "''"
    $"'($s)'"
}

export def sqlx [stmt] {
    open $env.SCRATCH_DB | query db $stmt
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
    let f = $config.filter? | default {}
    $config.default
    | columns
    | reduce -f {} {|i,a|
        let x = $d | get $i
        let x = if ($i in $f) {
            $x | do ($f | get $i) $x
        } else {
            $x
        }
        $a | insert $i $x
    }
}

export def table-upsert [
    config
    --action: closure
] {
    $in
    | table-merge $config --action $action
    | db-upsert $config.table $config.pk
}

