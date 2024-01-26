$env.comma_scope = {|_|{
    manifest: {
        #completion-generator.nu: modules/completion-generator
        argx.nu:                 modules/argx
        #taskfile.nu:            modules/taskfile
        ssh.nu:                  modules/network
        docker.nu:               modules/docker
        kubernetes.nu:           modules/kubernetes
        git.nu:                  modules/git/git-v2.nu
        git.md:                  modules/git/README.md
        nvim.nu:                 modules/nvim

        #just.nu:                custom-completions/just/just-completions.nu
        #mask.nu:                custom-completions/mask/mask-completions.nu

        power:                   modules/prompt/powerline
        cwdhist.nu:              modules/cwdhist

        #direnv.nu:              hooks/direnv
        #dynamic-load.nu:        hooks/dynamic-load
        #zoxide-menu.nu:         custom-menus
    }
    dest: $"($env.HOME)/world/nu_scripts"
}}

$env.comma = {|_|{
    inspect: {|a, s| {index: $_, scope: $s, args: $a} | table -e }
    export: {
        nu_scripts: {
            $_.act: {|a,s|
                let m = $s.manifest | transpose k v
                let m = if ($a | is-empty) { $m } else {
                    $m | filter {|x| $x.k in $a }
                }
                for x in $m {
                    cp -r $'($_.wd)/scripts/($x.k)' $'($s.dest)/($x.v)'
                }
            }
            $_.dsc: 'export files to nu_scripts'
            $_.cmp: {|a,s|
                $s.manifest | columns
            }
        }
        comma: {
            rsync -avp --delete --exclude=.git $'($_.wd)/scripts/comma/' $"($env.HOME)/world/comma"
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
                ', test all' | do $_.batch 'comma/test.nu'
                , export
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
}}
