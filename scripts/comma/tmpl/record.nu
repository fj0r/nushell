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
        proxy: $"http://(ip route | lines | get 0 | parse -r 'default via (?<gateway>[0-9\.]+) dev (?<dev>\w+)( proto dhcp src (?<lan>[0-9\.]+))?' | get 0.lan):7890"
        env: {
            PREFER_ALT: 1
            NEOVIM_LINE_SPACE: 2
            NEOVIDE_SCALE_FACTOR: 0.7
        }
    }
}}

$env.comma = {|_|{
    dev: {
        up: {
            $_.act: {|a,s|
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
            }
            $_.cmp: {|a,s|
                match ($a | length) {
                    1 => [(port 9990)]
                    _ => {}
                }
            }
        }
        down: {|a,s|
            let cs = ^$env.docker-cli ps | from ssv -a | get NAMES
            if $s.dev.id in $cs {
                lg level 2 { container: $s.dev.id } 'stop'
                pp $env.docker-cli rm -f $s.dev.id
            } else {
                lg level 3 { container: $s.dev.id } 'not running'
            }
        }
    }
    .: {
        .: {
            $_.action: {|a,s|
                let act = $a | str join ' '
                $', ($act)' | batch -i ',.nu'
            }
            $_.watch: { glob: ",.nu", clear: true }
            $_.completion: {|a,s|
                , -c ...$a
            }
            $_.desc: "reload & run ,.nu"
        }
        nu: {
            $_.action: {|a,s| nu $a.0 }
            $_.watch: { glob: '*.nu', clear: true }
            $_.completion: { ls *.nu | get name }
            $_.desc: "develop a nu script"
        }
        py: {
            $_.action: {|a,s| python3 $a.0 }
            $_.watch: { glob: '*.py', clear: true }
            $_.completion: { ls *.py| get name }
            $_.desc: "develop a python script"
        }
        created: {
            $_.action: {|a, s| $s.computed }
            $_.filter: [log_args]
            $_.desc: "created"
        }
        inspect: {|a, s| { index: $_, scope: $s, args: $a } | table -e }
        vscode-tasks: {
            $_.action: {
                mkdir .vscode
                ', --vscode -j' | batch ',.nu' -v | save -f .vscode/tasks.json
            }
            $_.desc: "generate .vscode/tasks.json"
            $_.watch: { glob: ',.nu' }
        }
    }
}}
