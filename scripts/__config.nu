########################################
const USRENV = '~/.env.nu'
const USRENV = if ($USRENV | path expand | path exists) {
    $USRENV
} else { 'dummy.nu' }
source $USRENV
########################################
source __env.nu

mkdir -v ($nu.data-dir | path join 'cache')

# settings
$env.config.show_banner = false
$env.config.use_kitty_protocol = true
$env.config.history.file_format = "sqlite"
$env.config.history.isolation = true
$env.config.table.header_on_separator = true
$env.config.table.mode = compact #light compact
$env.config.table.padding.left = 0


# config
use lg
use git *
use ssh *
use kubernetes *
use docker *
use cwdhist *
use comma *
use history-utils *
use history-utils/backup.nu *
use resolvenv
use nvim *
use netcat *
use process *
use os *


use sh.nu *
use nushell.nu *
use just.nu *
use git-cmp.nu *
use pwd-overlay.nu *
#use direnv.nu *
#use completion-generator.nu *
#use task.nu *

use network.nu *
use setup.nu *
use rustic *
use ollama *
use outdent.nu


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


########################################
const USRCFG = '~/.nu'
const USRCFG = if ($USRCFG | path expand | path exists) {
    $USRCFG
} else { 'dummy.nu' }
source $USRCFG
########################################

use __prefer_alt.nu prefer_alt_env
prefer_alt_env $env.PREFER_ALT?
