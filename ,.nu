export def main [...args:string@compos] {
    let manifest = {
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

        #direnv.nu:              hooks/direnv
        #dynamic-load.nu:        hooks/dynamic-load
        #zoxide-menu.nu:         custom-menus
    }

    let dest = $"($env.HOME)/world/nu_scripts"

    match $args.0 {
        'export' => {
            $manifest
            | transpose k v
            | each {|x|
                cp -v $'($env.PWD)/scripts/($x.k)' $'($dest)/($x.v)'
            }
        }
    }
}

def compos [...context] {
    $context | completion-generator from tree [
        export
    ]
}

