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
use scratch/integration/git.nu *
use llm *
use llm/shortcut.nu *
use llm/integration/web.nu *
# source llm/agents/kubernetes.nu
# source llm/agents/research.nu
use project *
use ssh *
use parser
use devcontainer

# autoload
use os *
# use nvim *
use netcat *
use nushell.nu *
use benchmark
use cwdhist *
use history-utils *
use history-utils/backup.nu *
# use resolvenv
use git-cmp.nu *
# use aichat-cmp.nu *
use rustic *
use minio *
use cdp *
use surrealdb
#use just.nu *
#use completion-generator.nu *

use power
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
        [ai, xterm_grey30]
        [kube, xterm_grey23]
        [time, xterm_grey27]
    ]
]
$env.NU_POWER_DECORATOR = 'plain'
$env.NU_POWER_FRAME = 'fill'
#$env.NU_POWER_FRAME = 'center'
#$env.NU_POWER_CONFIG.theme.separator_bar.char = "-"
use power/plugin/ai.nu *
use power/plugin/git.nu *
use power/plugin/kube.nu *
power set time {
    style: compact
}
power set ai {
    width: 120
}
power set kube {
    theme: {
        context: cyan
    }
    reverse: true
    separator: '@'
}
power init


def __init_plugin_query [] {
    const plugin_query = (
        $nu.current-exe | path dirname
        | path join $"nu_plugin_query(if $nu.os-info.family == 'windows' {'.exe'})"
    )
    print $"plugin add ($plugin_query)"
    print $"plugin use query"
}

