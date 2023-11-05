
## export

> copy files to `nu_scripts`

```nu
let manifest = {
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

  direnv.nu:       hooks/direnv
  dynamic-load.nu: hooks/dynamic-load
  zoxide-menu.nu:  custom-menus
}

let dest = $"($env.HOME)/world/nu_scripts"

$manifest
| transpose k v
| each {|x|
  cp -v $'($env.MASKFILE_DIR)/scripts/($x.k)' $'($dest)/($x.v)'
}
```

## test (x)

> test [pass flags through nu]

**OPTIONS**
* tax
    * flags: -t --tax
    * type: number
    * desc: What's the tax?
* port
    * flags: -p --port
    * type: string
    * desc: Which port to serve on
    * required


```nu
echo $env.port
echo $env.MASK
echo $env.MASKFILE_DIR
```
