export extern "nu" [
  --help(-h)                # Display this help message
  --stdin                   # redirect the stdin
  --login(-l)               # start as a login shell
  --interactive(-i)         # start as an interactive shell
  --version(-v)             # print the version
  --perf(-p)                # start and print performance metrics during startup
  --testbin:string          # run internal test binary
  --commands(-c):string     # run the given commands and then exit
  --config:string           # start with an alternate config file
  --env-config:string       # start with an alternate environment config file
  --log-level:string        # log level for performance logs
  --threads:int             # threads to use for parallel commands
  --table-mode(-m):string   # the table mode to use. rounded is default.
  ...script:string
]

export def timesit [--duration(-d): duration = 1sec, action: closure] {
    let begin = date now
    mut end = date now
    mut times = 0
    loop {
        do $action
        $end = date now
        $times += 1
        if ($end - $begin) > $duration { break }
    }
    let total = $end - $begin
    {
        times: $times
        total: $total
        average: ($total / $times)
    }
}

export def inspect-file [file:path='~/.cache/nonstdout'] {
    let x = $in
    $x | to yaml | save -f $file
    $x
}

export def nonstdout [--view(-v) --flush(-f)] {
    let o = $in
    let f = '~/.cache/nonstdout'
    if $view {
        tail -f ($f | path expand)
    } else {
        if $flush {
            $o | save -f $f
        } else {
            $"\n($o)" | save -a -f $f
        }
    }
}

export-env {
    $env.config.keybindings ++= [
        {
            modifier: control_alt
            keycode: char_r
            mode: [emacs, vi_normal, vi_insert]
            event: [
                { send: ExecuteHostCommand, cmd: 'exec nu' }
            ]
        }
    ]

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

def cmpl-config-scripts [] {
    ls ([$nu.default-config-dir scripts '**/*.nu'] | path join | into glob)
    | each {|x|
        $x.name
        | str replace ([$nu.default-config-dir scripts] | path join) ''
        | str substring 1..<-3
    }
}

export def 'config edit' [script: string@cmpl-config-scripts] {
    let f = ([$nu.default-config-dir scripts $'($script).nu'] | path join)
    e $f
}

def cmpl-config-table-modes [] {
    table -l
}

export def --env 'config table mode' [mode: string@cmpl-config-table-modes] {
    $env.config.table.padding = 1
    $env.config.table.mode = $mode
}

export def 'config reset' [] {
    config nu --default | save -f $nu.config-path
    [
        null
        null
        "### gen with `config reset`"
        r#'source ($nu.default-config-dir | path join 'scripts/main/mod.nu')'#
    ]
    | str join (char newline) | save -a $nu.config-path
    config env --default | save -f $nu.env-path
}
