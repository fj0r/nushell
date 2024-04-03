export def 'config update' [
    --vim (-v)
] {
    print '==> update nushell config'
    cd ($nu.config-path | path dirname)
    git pull
    #git log -1 --date=iso
    #source '($nu.config-path)'
    if ($vim) {
        print '==> update nvim config'
        for c in [
            ['etc' 'nvim']
            [$env.HOME '.config' 'nvim']
        ] {
            let p = $c | path join
            if ($p | path exists) {
                print $'--> ($p)'
                cd $p
                git pull
            }
        }
    }
}

def "nu-complete config scripts" [] {
    ls -s ([($nu.config-path | path dirname) scripts '*.nu'] | path join | into glob)
    | each {|x| $x.name | str substring ..-3 }
}

export def 'config edit' [script: string@"nu-complete config scripts"] {
    let f = ([($nu.config-path | path dirname) scripts $'($script).nu'] | path join)
    e $f
}

def "nu-complete config table-modes" [] {
    table -l
}

export def --env 'config table mode' [mode: string@"nu-complete config table-modes"] {
    $env.config.table.padding = 1
    $env.config.table.mode = $mode
}

export def 'config reset' [] {
    config nu --default | save -f $nu.config-path
    echo $"(char newline)source __config.nu" | save -a $nu.config-path
    config env --default | save -f $nu.env-path
}

