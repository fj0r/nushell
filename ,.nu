$env.comma_scope = {|_|{
    manifest: [
    { from: completion-generator.nu, to: modules/completion-generator, disable: true }
    { from: argx.nu, to: modules/argx }
    { from: taskfile.nu, to: modules/taskfile, disable: true }
    { from: ssh.nu, to: modules/network }
    { from: docker.nu, to: modules/docker }

    { from: kubernetes.nu, to: modules/kubernetes }
    { from: refine.nu, to: modules/kubernetes }
    { from: lg.nu, to: modules/kubernetes }

    { from: git.nu, to: modules/git/git-v2.nu }
    { from: git.md, to: modules/git/README.md }

    { from: nvim.nu, to: modules/nvim }

    { from: just.nu, to: custom-completions/just/just-completions.nu, disable: true }
    { from: mask.nu, to: custom-completions/mask/mask-completions.nu, disable: true }

    { from: power, to: modules/prompt/powerline, disable: true }
    { from: cwdhist.nu, to: modules/cwdhist }
    { from: history-utils.nu, to: modules/history-utils, disable: true }
    { from: resolvenv.nu, to: modules/resolvenv, disable: true }
    { from: resolvenv.md, to: modules/resolvenv, disable: true }

    { from: direnv.nu, to: hooks/direnv, disable: true }
    { from: dynamic-load.nu, to: hooks/dynamic-load, disable: true }
    { from: zoxide-menu.nu, to: custom-menus, disable: true }
    ]
    dest: $"($env.HOME)/world/nu_scripts"
}}

$env.comma = {|_|{
    export: {
        nu_scripts: {
            $_.act: {|a,s|
                let m = $s.manifest | filter {|x| not ($x.disable? | default false) }
                let m = if ($a | is-empty) { $m } else {
                    $m | where to in $a
                }
                for x in $m {
                    pp cp -r $'($_.wd)/scripts/($x.from)' $'($s.dest)/($x.to)'
                }
            }
            $_.dsc: 'export files to nu_scripts'
            $_.cmp: {|a,s|
                $s.manifest | group-by to | columns
            }
        }
        comma: {
            cp $'($_.wd)/scripts/lg.nu' $'($_.wd)/scripts/comma/lib/lg.nu'
            pp rsync -avp --delete --exclude=.git $'($_.wd)/scripts/comma/' $"($env.HOME)/world/comma"
        }
    }
    upgrade: {
        $_.act: {|a, e|
            e $a.0
        }
        $_.cmp: {|a, e|
            let s = fd ',\.nu' ~ | lines
            $s
            | each {|x| ls $x}
            | flatten
            | sort-by modified
            | get name
        }
        $_.dsc: ',.nu -- commafile'
    }
    test: {
        comma: {
            $_.act: {
                ', test all' | batch 'comma/test.nu'
                , export nu_scripts
            }
            $_.wth: {
                glob: '*.nu'
                clear: true
            }
            $_.dsc: 'copy this to uplevel'
        }
        poll: {
            $_.act: {
                print $env.PWD
            }
            $_.wth: {
                interval: 3sec
                clear: true
            }
        }
        ping: {
            $_.act: { ping 127.0.0.1 -c 3 }
            $_.wth: {
                interval: 2sec
                clear: true
            }
        }
    }
    dev: {
        source scripts/resolvenv.nu
        let x = resolvenv select wlan0 [
            [{wifi: 'pan', screen: { port: 'hdmi-0' }}, { print 1 }]
            [_, { print 0 }]
        ]
    }
    .: {
        created: {
            $_.action: {|a, s| $s.computed }
            $_.filter: [log_args]
            $_.desc: "created"
        }
        inspect: {|a, s| {index: $_, scope: $s, args: $a} | table -e }
        reload: {
            $_.action: {|a,s|
                let act = $a | str join ' '
                $', ($act)' | batch ',.nu'
            }
            $_.watch: { glob: "**/*nu", clear: true }
            $_.completion: {|a,s|
                , -c ...$a
            }
            $_.desc: "reload ,.nu"
        }
        vscode-tasks: {
            $_.action: {
                mkdir .vscode
                ', --vscode -j' | batch ',.nu' | save -f .vscode/tasks.json
            }
            $_.desc: "generate .vscode/tasks.json"
            $_.watch: { glob: ',.nu' }
        }
    }
}}
