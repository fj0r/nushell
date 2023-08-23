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

export def-env 'config table mode' [mode: string@"nu-complete config table-modes"] {
    $env.config.table.padding = 1
    $env.config.table.mode = $mode
}
