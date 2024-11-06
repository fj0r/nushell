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
        "_: |-
        preset:
        - name: rust
          image: rust
          daemon: false
          environment:
            CARGO_HOME: /opt/cargo
          volumns:
            .: /world
            ~/.cargo: /opt/cargo
          ports:
            '8000': 80
          command: []
          options:
          - --cap-add=SYS_ADMIN
          - --cap-add=SYS_PTRACE
          - --security-opt
          - seccomp=unconfined
        - name: ollama-gpu
          image: ollama
          container_name: ollama
          daemon: true
          environment: {}
          volumns:
            ~/.ollama: /root/.ollama
            ~/pub/Platform/llm: /world
          ports:
            '11434': 11434
          command: []
          options:
          - --gpus
          - all
          - --ipc=host
        - name: ollama
          image: ollama
          container_name: ollama
          daemon: true
          environment: {}
          volumns:
            ~/.ollama: /root/.ollama
            ~/pub/Platform/llm: /world
          ports:
            '11434': 11434
          command: []
          options:
          - --ipc=host
        - name: postgres
          image: postgres
          container_name: postgres
          daemon: true
          environment: {}
          volumns: {}
          ports:
            '5432': 5432
          command: []
          options: []
        - name: surreal
          image: surreal
          container_name: surrealdb
          daemon: true
          environment: {}
          volumns: {}
          ports:
            '8000': 8000
          command: []
          options: []
        "
        | from yaml | get _
        | save -f $env.CONTCONFIG
    }
}


export use core.nu *
export use utils.nu *
export use registry.nu *
export use buildah.nu *
