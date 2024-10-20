export-env {
    for c in [podman nerdctl docker] {
        if (which $c | is-not-empty) {
            $env.CONTCTL = $c
            break
        }
    }
    if 'CONTCONFIG' not-in $env {
        $env.CONTCONFIG = [$nu.data-dir 'container-preset.yml'] | path join
    }
    if not ($env.CONTCONFIG | path exists) {
        {
            preset: [
                [name, image, daemon, env, volumn, port, cmd, args];
                [rust, 'rust', false, {CARGO_HOME: /opt/cargo}, {.: /world, ~/.cargo:/opt/cargo}, {8000: 80}, [], [--cap-add=SYS_ADMIN --cap-add=SYS_PTRACE --security-opt seccomp=unconfined]]
                [ollama, 'ollama', true, {}, {~/.ollama: /root/.ollama}, {11434: 11434}, [], [--runtime nvidia --gpus all --ipc=host]]
                [postgres, 'postgres', true, {}, {}, {5432: 5432}, [], []]
                [surreal, 'surreal', true, {}, {}, {8000: 8000}, [], []]
            ]

        } | to yaml | save -f $env.CONTCONFIG
    }
}


export use core.nu *
export use utils.nu *
export use registry.nu *
export use buildah.nu *
