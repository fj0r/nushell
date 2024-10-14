export alias d = container
export alias dp = container-list
export alias dr = container-create
export alias dcr = container-remove
export alias da = container-attach
export alias dl = container-log
export alias dlt = container-log-trunc
export alias dcp = container-copy-file
export alias dh = container-history
export alias di = image-list
export alias dil = image-layer
export alias dps = image-push
export alias dpl = image-pull
export alias dsv = image-save
export alias dld = image-load
export alias dt = image-tag
export alias drmi = image-remove
export alias dsp = system-prune
export alias dspall = system-prune-all
export alias dvl = volume-list
export alias dvc = volume-create
export alias dvi = volume-inspect
export alias dvr = volume-remove
export alias dn = containers-network-list
export alias dnc = containers-network-create
export alias dnr = containers-network-remove

use complete.nu *
def cmpl-preset [] {
    open $env.CONTCONFIG | get preset.name
}

export def dx [
    preset:string@cmpl-preset
    ...cmd
    --vols(-v): any = {}
    --ports(-p): any = {}
    --envs(-e): any = {}
    --proxy: string@cmpl-docker-run-proxy
    --ssh(-s): string@cmpl-docker-run-sshkey
    --debug(-d)
    --privileged(-P)
    --netadmin
    --with-x
    --dry-run
] {
    let c = open $env.CONTCONFIG | get preset | where name == $preset
    if ($c | is-empty) {
        print $"(ansi grey)Oops!(ansi reset)"
    } else {
        let c = $c.0
        let image = $c.image
        let cmd = if ($cmd | is-empty) { $c.cmd } else { $cmd }
        (container-create
            --envs {...$c.env, ...$envs}
            --vols {...$c.volumn, ...$vols}
            --ports {...$c.port, ...$ports}
            --debug=$debug
            --privileged=$privileged
            --netadmin=$netadmin
            --with-x=$with_x
            --proxy=$proxy
            --ssh=$ssh
            --dry-run=$dry_run
            $image ...$cmd)
    }
}
