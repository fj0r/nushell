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
use llm *
use llm/shortcut.nu *
use todo *
use todo/shortcut.nu *
use todo/integration.nu *
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
use setup.nu *
use history-utils *
use history-utils/backup.nu *
use resolvenv
use git-cmp.nu *
use rustic *
#use just.nu *
#use completion-generator.nu *


use power
use power/plugin/git.nu *
use power/plugin/kube.nu *
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

if (which atuin | is-not-empty) {
    source atuin.nu
}
