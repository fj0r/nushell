export-env {
    for c in [podman nerdctl docker] {
        if (which $c | is-not-empty) {
            $env.CONTCTL = $c
            break
        }
    }
    if 'CONTCONFIG' not-in $env {
        $env.CONTCONFIG = [$nu.data-dir 'container.toml'] | path join
    }
    if not ($env.CONTCONFIG | path exists) {
        {
            preset: [
                [name, image, env, volum, port, cmd];
                [rust, 'rust', {}, {}, {}, []]
            ]

        } | to toml | save -f $env.CONTCONFIG
    }
}


export use core.nu *
export use registry.nu *
export use buildah.nu *
