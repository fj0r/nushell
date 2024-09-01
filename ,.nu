$env.comma_scope = {}

$env.comma = {|_|{
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

'manifest'
| comma val null [
    { from: argx/*, to: modules/argx }
    { from: ssh/*, to: modules/ssh }
    { from: docker/*, to: modules/docker }

    { from: kubernetes/*, to: modules/kubernetes }
    { from: lg/*, to: modules/lg }

    { from: git/*, to: modules/gitv2 }

    { from: nvim/*, to: modules/nvim }
    { from: process/*, to: modules/process }

    { from: just.nu, to: custom-completions/just/just-completions.nu, disable: true }
    { from: mask.nu, to: custom-completions/mask/mask-completions.nu, disable: true }

    { from: power/*, to: modules/prompt/powerline, disable: false }
    { from: cwdhist/*, to: modules/cwdhist }
    { from: history-utils/mod.nu, to: modules/history-utils, disable: false }
    { from: resolvenv/*, to: modules/resolvenv, disable: true }

    { from: direnv.nu, to: hooks/direnv, disable: true }
]

'dest'
| comma val null $"($env.HOME)/world/nu_scripts"

'export'
| comma dir { desc: '...' }

'export nu_scripts'
| comma fun {|a,s,_|
    let m = $s.manifest | filter {|x| not ($x.disable? | default false) }
    let m = if ($a | is-empty) { $m } else {
        $m | where to in $a
    }
    for x in $m {
        cp -r ($'($_.wd)/scripts/($x.from)' | into glob) $'($s.dest)/($x.to)'
    }
} {
    dsc: 'export files to nu_scripts'
    cmp: {|a,s|
        $s.manifest | group-by to | columns
    }
}

'import devcontainer'
| comma fun {|a,s,_|
    for i in [mod.nu] {
        cp -r $"($env.HOME)/world/dev-container/($i)" scripts/devcontainer/
    }
}

'export comma'
| comma fun {|a,s,_|
    pp rsync -avp --delete --exclude=.git $'($_.wd)/scripts/comma/' $"($env.HOME)/world/comma"
}

'test comma'
| comma fun {
    ', test all' | batch 'comma/test.nu'
    , export nu_scripts
} {
    wth: {
        glob: '*.nu'
        clear: true
    }
    dsc: 'copy this to uplevel'
}

'test poll'
| comma fun {
    ping 127.0.0.1 -c 3
} {
    wth: {
        interval: 3sec
        clear: true
    }
}

