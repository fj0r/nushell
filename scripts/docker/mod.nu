export-env {
    for c in [podman nerdctl docker] {
        if (which $c | is-not-empty) {
            $env.CONTCTL = $c
            break
        }
    }
}

export use core.nu *
export use registry.nu *
export use buildah.nu *
