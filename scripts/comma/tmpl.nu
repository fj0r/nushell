$env.comma_scope = {|_|{
    created: '{{time}}'
    computed: {$_.computed:{|a, s, m| $'($s.created)($a)' }}
    log_args: {$_.filter:{|a, s, m|
        if $m == 'completion' { return }
        do $_.tips 'received arguments' $a
    }}
}}

$env.comma = {|_|{
    start: {
        $_.act: {|a,s|
            log msg start
        }
        $_.cmp: {|a,s|
            match ($a | length) {
                1 => []
                _ => {}
            }
        }
    }
    stop: {
        log wrn 'stop'
    }
    .: {
        .: {
            $_.action: {|a,s|
                let act = $a | str join ' '
                $', ($act)' | batch ',.nu'
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
        inspect: {|a, s| {index: $_, scope: $s, args: $a} | table -e }
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
