const __dyn_load = if ('~/.env.nu' | path exists) { '~/.env.nu' } else { 'dummy.nu' }
source $__dyn_load
source __env.nu

mkdir -v ($nu.data-dir | path join 'cache')

# settings
$env.config.show_banner = false
$env.config.use_kitty_protocol = true
$env.config.filesize.metric = true
$env.config.datetime_format.normal = '%m/%d/%y %H:%M:%S'
$env.config.datetime_format.table = '%m/%d/%y %H:%M:%S'
$env.config.history.file_format = "sqlite"
$env.config.history.isolation = true
$env.config.completions.algorithm = 'fuzzy'
$env.config.table.header_on_separator = true
$env.config.table.mode = 'compact' #light compact
$env.config.table.padding = 0


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

# const plugin_msgpackz = (
#     [($nu.config-path | path dirname), 'plugin.msgpackz'] | path join
# )
#
# const plugin_query = (
#     $nu.current-exe | path dirname
#     | path join $"nu_plugin_query(if $nu.os-info.family == 'windows' {'.exe'})"
# )
# plugin add $plugin_query
# plugin use --plugin-config $plugin_msgpackz $plugin_query


const __dyn_load = if ('~/.nu' | path exists) { '~/.nu' } else { 'dummy.nu' }
source $__dyn_load

use __prefer_alt.nu prefer_alt_env
prefer_alt_env $env.PREFER_ALT?
