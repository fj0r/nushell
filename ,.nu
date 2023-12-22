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

        power.nu:                modules/prompt/powerline
        power_git.nu:            modules/prompt/powerline
        power_kube.nu:           modules/prompt/powerline
        power_utils.nu:          modules/prompt/powerline
        power.md:                modules/prompt/powerline/README.md

        cwdhist.nu:              modules/cwdhist
        comma.nu:                modules/comma
        comma.md:                modules/comma/README.md

        #direnv.nu:              hooks/direnv
        #dynamic-load.nu:        hooks/dynamic-load
        #zoxide-menu.nu:         custom-menus
    }
    dest: $"($env.HOME)/world/nu_scripts"
}}

$env.comma = {|_|{
    inspect: {|a, s| {index: $_, scope: $s, args: $a} | table -e }
    set: {|a, s| do $_.set {|config| $config | upsert a 123 } }
    export: {
        $_.act: {|a,s|
            let m = $s.manifest | transpose k v
            let m = if ($a | is-empty) { $m } else {
                $m | filter {|x| $x.k in $a }
            }
            for x in $m {
                cp -v $'($_.wd)/scripts/($x.k)' $'($s.dest)/($x.v)'
            }
        }
        $_.dsc: 'export files to nu_scripts'
        $_.cmp: {|a,s|
            $s.manifest | columns
        }
    }
    upgrade: {
        $_.act: {|a, e|
            if ($a.0? | is-empty) {
                fd ',\.nu' ~
                | lines
                | each {|x|
                    ^$env.EDITOR $x
                }
            } else {
                e $a.0
            }
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
}}
