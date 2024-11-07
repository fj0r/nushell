# config
use argx
use lg
use perform-or-print *
use git *
use git/shortcut.nu *
use kubernetes *
use kubernetes/shortcut.nu *
use docker *
use docker/shortcut.nu *
use scratch *
use scratch/shortcut.nu *
use scratch/integration.nu *
use llm *
use llm/shortcut.nu *
#use legacy/todo *
#use legacy/todo/shortcut.nu *
#use legacy/todo/integration.nu *
use project *
use ssh *
use cwdhist *
use parser
use devcontainer

# autoload
use os *
use nvim *
use netcat *
use nushell.nu *
use benchmark
use history-utils *
use history-utils/backup.nu *
use resolvenv
use git-cmp.nu *
use rustic *
use surrealdb
#use just.nu *
#use completion-generator.nu *


$env.NU_POWER_SINGLE_WIDTH = '↑↓┌└'
$env.NU_POWER_DECORATOR = 'plain'
$env.NU_POWER_FRAME = 'fill'
$env.NU_POWER_FRAME_HEADER = {
    upperleft: '┌|'
    upperleft_size: 2
    lowerleft: '└'
}
$env.NU_POWER_SCHEMA = [
    [
        [source, color];
        [pwd, xterm_grey23]
        [git, xterm_grey30]
    ],
    [
        [source, color];
        [proxy, xterm_grey39]
        [host, xterm_grey30]
        [kube, xterm_grey23]
        [time, xterm_grey27]
    ]
]
use power
use power/plugin/git.nu *
use power/plugin/kube.nu *
power set time {
    config: { style: compact }
}
power set kube {
    theme: {
        context: cyan
    }
    config: {
        reverse: true
        separator: '@'
    }
}
power init

