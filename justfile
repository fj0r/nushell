export:
  #!/usr/local/bin/nu

  let manifest = {
    ssh.nu:          modules/network
    docker.nu:       modules/docker
    kubernetes.nu:   modules/kubernetes
    git.nu:          modules/git
    nvim.nu:         modules/nvim
    after.nu:        modules/after
    log.nu:          modules/log

    just.nu:         custom-completions/just

    power.nu:        modules/prompt/powerline
    power_git.nu:    modules/prompt/powerline
    power_kube.nu:   modules/prompt/powerline
    power.md:        modules/prompt/powerline/README.md

    direnv.nu:       hooks/direnv
    dynamic-load.nu: hooks/dynamic-load
    zoxide-menu.nu:  custom-menus
  }

  let dest = $"($env.HOME)/world/nu_scripts"

  $manifest
  | transpose k v
  | each {|x|
    cp $'{{invocation_directory()}}/scripts/($x.k)' $'($dest)/($x.v)'
  }

