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
        "
        preset:
        - name: rust
          image: rust
          daemon: false
          env:
            CARGO_HOME: /opt/cargo
          volumn:
            .: /world
            ~/.cargo: /opt/cargo
          port:
            '8000': 80
          cmd: []
          args:
          - --cap-add=SYS_ADMIN
          - --cap-add=SYS_PTRACE
          - --security-opt
          - seccomp=unconfined
        - name: ollama-gpu
          image: ollama
          container_name: ollama
          daemon: true
          env: {}
          volumn:
            ~/.ollama: /root/.ollama
            ~/pub/Platform/llm: /world
          port:
            '11434': 11434
          cmd: []
          args:
          - --gpus
          - all
          - --ipc=host
        - name: ollama
          image: ollama
          container_name: ollama
          daemon: true
          env: {}
          volumn:
            ~/.ollama: /root/.ollama
            ~/pub/Platform/llm: /world
          port:
            '11434': 11434
          cmd: []
          args:
          - --ipc=host
        - name: postgres
          image: postgres
          container_name: postgres
          daemon: true
          env: {}
          volumn: {}
          port:
            '5432': 5432
          cmd: []
          args: []
        - name: surreal
          image: surreal
          container_name: surrealdb
          daemon: true
          env: {}
          volumn: {}
          port:
            '8000': 8000
          cmd: []
          args: []
        "
        | lines
        | range 1..-1
        | str substring 8..
        | str join (char newline)
        | save -f $env.CONTCONFIG
    }
}


export use core.nu *
export use utils.nu *
export use registry.nu *
export use buildah.nu *
