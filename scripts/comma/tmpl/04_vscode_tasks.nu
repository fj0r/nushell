'. vscode tasks'
| comma fun {
    mkdir .vscode
    ', --vscode -j' | batch ',.nu' -v | save -f .vscode/tasks.json
} {
    desc: "generate .vscode/tasks.json"
    watch: { glob: ',.nu' }
}
