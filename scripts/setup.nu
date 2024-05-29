export-env {
    $env.CONFIG_FILE_PATH = [
        {
            name: nushell
            bin: nu
            cfg: [
                ['etc', 'nushell']
                $nu.default-config-dir
            ]
        }
        {
            name: neovim
            bin: nvim
            cfg: [
                ['etc' 'nvim']
                [$env.HOME '.config' 'nvim']
            ]
        }
    ]
}

export def 'config update' [
    --rebase(-r)
] {
    for i in $env.CONFIG_FILE_PATH {
        if (which $i.bin | is-empty) { continue }
        print $'==> update ($i.name) config'
        for j in $i.cfg {
            let p = $j | path join
            if ($p | path exists) {
                print $'--> ($p | str replace $env.HOME "~")'
                cd $p
                git pull ...(if $rebase {[--rebase]} else {[]})
                git log -1 --date=iso
            }
        }

    }
}

def "nu-complete config scripts" [] {
    ls -s ([$nu.default-config-dir scripts '**/*.nu'] | path join | into glob)
    | each {|x| str substring ..-4 }
}

export def 'config edit' [script: string@"nu-complete config scripts"] {
    let f = ([$nu.default-config-dir scripts $'($script).nu'] | path join)
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
    [
        null
        null
        "### gen with `config reset`"
        r#'source ($nu.default-config-dir | path join 'scripts/__config.nu')'#
    ]
    | str join (char newline) | save -a $nu.config-path
    config env --default | save -f $nu.env-path
}

