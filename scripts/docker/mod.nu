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
        - name: qbittorrent
          container_name: qbittorrent
          image: linuxserver/qbittorrent
          daemon: true
          environment:
            PUID: 1000
            PGID: 1000
            UMASK: 002
            TZ: Etc/UTC
            WEBUI_PORT: 8080
            TORRENTING_PORT: 6881
          ports:
            '8080': 8080
            '6881': 6881
            '6881/udp': 6881
          volumns:
            ~/.config/qbittorrent: /config/qBittorrent
            ~/Downloads/qbittorrent: /downloads
          command: []
          options: []
        - name: mitmproxy
          image: mitmproxy/mitmproxy
          daemon: false
          container_name: mitmproxy
          environment: {}
          ports: {}
          volumns:
            ~/.mitmproxy: /home/mitmproxy/.mitmproxy
          command:
          - mitmproxy
          - -p
          - 8989
          options:
          - --network=host
        - name: mitmweb
          image: mitmproxy/mitmproxy
          daemon: false
          container_name: mitmproxy
          environment: {}
          ports: {}
          volumns:
            ~/.mitmproxy: /home/mitmproxy/.mitmproxy
          command:
          - mitmweb
          - --web-host
          - 0.0.0.0
          - -p
          - 8989
          options:
          - --network=host
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
          environment:
            SURREAL_USER: foo
            SURREAL_PASS: foo
            SURREAL_STORE: rocksdb
            SURREAL_EXPERIMENTAL_GRAPHQL: 'true'
            SURREAL_ROCKSDB_BACKGROUND_FLUSH: 'true'
          volumns: {}
          ports:
            '8000': 8000
          command: []
          options: []
        - name: whisper
          image: ghcr.io/fj0r/0x:whisper
          container_name: whisper
          daemon: true
          environment:
            ASR_MODEL: small
          volumns:
            ~/.cache/whisper: /root/.cache/whisper
          ports:
            '4010': 9000
          command: []
          options:
          - --gpus
          - all
        - name: iggy
          image: iggyrs/iggy
          container_name: iggy
          daemon: true
          environment: {}
          volumns:
            ~/.iggy_data: /local_data
          ports:
            '3000': 3000
            '8080': 8080
            '8090': 8090
          command: []
          options: []
        - name: redpanda
          image: docker.redpanda.com/redpandadata/redpanda:v24.2.10
          container_name: redpanda
          daemon: true
          environment: {}
          volumns:
            ~/.redpanda_data: /var/lib/redpanda/data
          ports:
            '18081': 18081
            '18082': 18082
            '19092': 19092
          command:
            - redpanda
            - start
            - --kafka-addr
            - internal://0.0.0.0:9092,external://0.0.0.0:19092
            - --advertise-kafka-addr
            - internal://127.0.0.1:9092,external://172.178.5.123:19092
            - --pandaproxy-addr
            - internal://0.0.0.0:8082,external://0.0.0.0:18082
            - --advertise-pandaproxy-addr
            - internal://redpanda:8082,external://172.178.5.123:18082
            - --schema-registry-addr
            - internal://0.0.0.0:8081,external://0.0.0.0:18081
            #- --rpc-addr redpanda:33145
            #- --advertise-rpc-addr redpanda:33145
            - --overprovisioned
            - --smp 1
            - --memory 1G
            - --reserve-memory 0M
            - --node-id 0
            - --check=false
          options: []
        "
        | from yaml | get _
        | save -f $env.CONTCONFIG
    }
}


export use base.nu *
export use core.nu *
export use utils.nu *
export use registry.nu *
export use buildah.nu *
