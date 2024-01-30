$env.comma_scope = {|_|{
    created: '{{time}}'
    computed: {$_.computed:{|a, s| $'($s.created)($a)' }}
    log_args: {$_.filter:{|a, s| do $_.tips 'received arguments' $a }}
}}

$env.comma = {|_|{
    created: {|a, s| $s.computed }
    inspect: {|a, s| {index: $_, scope: $s, args: $a} | table -e }
    vscode-tasks: {
        $_.action: {
            mkdir .vscode
            ', --vscode -j' | do $_.batch ',.nu' | save -f .vscode/tasks.json
        }
        $_.desc: "generate .vscode/tasks.json"
        $_.watch: { glob: ',.nu' }
    }
    start: {
        do $_.log 1 'start'
    }
    stop: {
        l1 'stop'
    }
    dev: {
        comma: {
            $_.action: {|a,s|
                let act = $a | str join ' '
                $', ($act)' | do $_.batch ',.nu'
            }
            $_.watch: { glob: ",.nu", clear: true }
            $_.completion: {|a,s|
                , -c ...$a
            }
            $_.desc: "reload ,.nu"
        }
    }
}}
