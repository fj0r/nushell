$env.comma_scope = {|_|{
    created: '{{time}}'
    computed: {$_.computed:{|a, s, m| $'($s.created)($a)' }}
    log_args: {$_.filter:{|a, s, m|
        if $m == 'completion' { return }
        do $_.tips 'received arguments' $a
    }}
    dev: {
        container: [io:x srv]
        id: ($_.wd | path parse | get stem)
        wd: '/world'
        pubkey: 'id_ed25519.pub'
        user: root
        privileged: false
        proxy: 'http://192.168.99.100:7890'
        env: {
            PREFER_ALT: 1
            NEOVIM_LINE_SPACE: 2
            NEOVIDE_SCALE_FACTOR: 0.7
        }
    }
}}

$env.comma = {}

comma action [dev up] {|a,s,_|
    , dev down
    let port = $a.0
    lg level 3 {
        container: $s.dev.id, workdir: $s.dev.wd
        port: $port, pubkey: $s.dev.pubkey
    } start
    let privileged = if $s.dev.privileged {[
        --privileged
    ]} else {[
        --cap-add=SYS_ADMIN
        --cap-add=SYS_PTRACE
        --security-opt seccomp=unconfined
        --cap-add=NET_ADMIN
        --device /dev/net/tun
    ]}
    let proxy = if ($s.dev.proxy? | is-empty) {[]} else {[
        -e $"http_proxy=($s.dev.proxy)"
        -e $"https_proxy=($s.dev.proxy)"
    ]}
    let x = [
        -e $"DISPLAY=($env.DISPLAY)"
        -v /tmp/.X11-unix:/tmp/.X11-unix
    ]
    let sshkey = cat ([$env.HOME .ssh $s.dev.pubkey] | path join) | split row ' ' | get 1
    let dev = [
        -e $"NVIM_WORKDIR=($s.dev.wd)"
        -v $"($_.wd):($s.dev.wd)"
        -w $s.dev.wd
        -p $"($port):9999"
        -e $"ed25519_($s.dev.user)=($sshkey)"
    ]
    let cu = $s.dev.env | transpose k v
    | each {|x| [-e $"($x.k)=($x.v)"]}
    | flatten
    pp $env.docker-cli run ...[
        --name $s.dev.id
        -d
        ...$privileged
        ...$x
        ...$dev
        ...$proxy
        ...$cu
    ] ...$s.dev.container
} {
    cmp: {|a,s|
        match ($a | length) {
            1 => [(port 9990)]
            _ => {}
        }
    }
}

comma action [dev down] {|a,s|
    let cs = ^$env.docker-cli ps | from ssv -a | get NAMES
    if $s.dev.id in $cs {
        lg level 2 { container: $s.dev.id } 'stop'
        pp $env.docker-cli rm -f $s.dev.id
    } else {
        lg level 3 { container: $s.dev.id } 'not running'
    }
}

comma action '. .' {|a,s|
    let act = $a | str join ' '
    $', ($act)' | batch -i ',.nu'
} {
    watch: { glob: ",.nu", clear: true }
    completion: {|a,s|
        , -c ...$a
    }
    desc: "reload & run ,.nu"
}

comma action '. nu' {|a,s| nu $a.0 } {
    watch: { glob: '*.nu', clear: true }
    completion: { ls *.nu | get name }
    desc: "develop a nu script"
}

comma action '. py' {|a,s| python3 $a.0 } {
    watch: { glob: '*.py', clear: true }
    completion: { ls *.py| get name }
    desc: "develop a python script"
}

comma action '. created' {|a, s| $s.computed } {
    filter: [log_args]
    desc: "created"
}

comma action '. inspect' {|a, s, _| { index: $_, scope: $s, args: $a } | table -e }
comma action '. vscode-tasks' {
    mkdir .vscode
    ', --vscode -j' | batch ',.nu' | save -f .vscode/tasks.json
} {
    desc: "generate .vscode/tasks.json"
    watch: { glob: ',.nu' }
}
