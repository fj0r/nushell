$env.comma_scope = {|_|{
    created: '{{time}}'
    computed: {$_.computed:{|a, s| $'($s.created)($a)' }}
    log_args: {$_.filter:{|a, s| do $_.tips 'received arguments' $a }}
}}

$env.comma = {|_|{
    start: {
        do $_.log 1 'start'
    }
    stop: {
        l1 'stop'
    }
    .: {
        created: {
            $_.action: {|a, s| $s.computed }
            $_.filter: [log_args]
            $_.desc: "created"
        }
        inspect: {|a, s| {index: $_, scope: $s, args: $a} | table -e }
        reload: {
            $_.action: {|a,s|
                let act = $a | str join ' '
                $', ($act)' | batch ',.nu'
            }
            $_.watch: { glob: ",.nu", clear: true }
            $_.completion: {|a,s|
                , -c ...$a
            }
            $_.desc: "reload ,.nu"
        }
        vscode-tasks: {
            $_.action: {
                mkdir .vscode
                ', --vscode -j' | batch ',.nu' | save -f .vscode/tasks.json
            }
            $_.desc: "generate .vscode/tasks.json"
            $_.watch: { glob: ',.nu' }
        }
    }
}}
