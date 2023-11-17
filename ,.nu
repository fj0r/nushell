export def main [...args:string@comp] {
    let manifest = {
        cmd_parse.nu:    modules/cmd_parse
        ssh.nu:          modules/network
        docker.nu:       modules/docker
        kubernetes.nu:   modules/kubernetes
        git.nu:          modules/git/git-v2.nu
        git.md:          modules/git/README.md
        nvim.nu:         modules/nvim
        after.nu:        modules/after
        log.nu:          modules/log

        #just.nu:         custom-completions/just/just-completions.nu
        mask.nu:         custom-completions/mask/mask-completions.nu

        power.nu:        modules/prompt/powerline
        power_git.nu:    modules/prompt/powerline
        power_kube.nu:   modules/prompt/powerline
        power_utils.nu:  modules/prompt/powerline
        power.md:        modules/prompt/powerline/README.md

        cwdhist.nu:      modules/cwdhist

        #direnv.nu:       hooks/direnv
        #dynamic-load.nu: hooks/dynamic-load
        #zoxide-menu.nu:  custom-menus
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

def comp [context: string, offset: int] {
    let size = $context | str substring 0..$offset | split row ' ' | length
    if $size < 3 {
        ['export']
    } else if $size < 4 {
        []
    }
}
