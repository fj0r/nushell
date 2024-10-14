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
                [name, image, env, volumn, port, cmd];
                [rust, 'rust', {CARGO_HOME: /opt/cargo}, {.: /world, ~/.cargo:/opt/cargo}, {8000: 80}, []]
            ]

        } | to toml | save -f $env.CONTCONFIG
    }
}


export use core.nu *
export use utils.nu *
export use registry.nu *
export use buildah.nu *
