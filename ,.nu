$env.comma_scope = {
    manifest: {
        #completion-generator.nu: modules/completion-generator
        argx.nu:                 modules/argx
        #taskfile.nu:             modules/taskfile
        ssh.nu:                  modules/network
        docker.nu:               modules/docker
        kubernetes.nu:           modules/kubernetes
        git.nu:                  modules/git/git-v2.nu
        git.md:                  modules/git/README.md
        nvim.nu:                 modules/nvim
        log.nu:                  modules/log

        #just.nu:                custom-completions/just/just-completions.nu
        mask.nu:                 custom-completions/mask/mask-completions.nu

        power.nu:                modules/prompt/powerline
        power_git.nu:            modules/prompt/powerline
        power_kube.nu:           modules/prompt/powerline
        power_utils.nu:          modules/prompt/powerline
        power.md:                modules/prompt/powerline/README.md

        cwdhist.nu:              modules/cwdhist
        comma.nu:                modules/comma

        #direnv.nu:              hooks/direnv
        #dynamic-load.nu:        hooks/dynamic-load
        #zoxide-menu.nu:         custom-menus
    }
    dest: $"($env.HOME)/world/nu_scripts"
}

$env.comma = {
    export: {
        $env.comm.act: {|argv, cv|
            $cv.manifest
            | transpose k v
            | each {|x|
                cp -v $'($env.PWD)/scripts/($x.k)' $'($cv.dest)/($x.v)'
            }
        }
        $env.comm.dsc: 'export files to nu_scripts'
    }
    upgrade_commafile: {
        $env.comm.act: {|a, e|
            if ($a.0? | is-empty) {
                fd ',\.nu' ~
                | lines
                | each {|x|
                    ^$env.EDITOR $x
                }
            } else {
                ^$env.EDITOR $a.0
            }
        }
        $env.comm.cmp: {|a, e|
            fd ',\.nu' ~
            | lines
        }
    }
}
