########################################
const USRENV = '~/.env.nu'
const USRENV = if ($USRENV | path expand | path exists) {
    $USRENV
} else { 'dummy.nu' }
source $USRENV
########################################
source __env.nu

# settings
$env.config.show_banner = false
$env.config.use_kitty_protocol = true
$env.config.history.file_format = "sqlite"
$env.config.history.isolation = true
$env.config.table.header_on_separator = true
$env.config.table.mode = compact #light compact
$env.config.table.padding.left = 0


# config
use log.nu
use cwdhist.nu *
use nushell.nu *
use sys.nu *
use just.nu *
use git-cmp.nu *
use git.nu *
use ssh.nu *
use kubernetes.nu *
use docker.nu *
use sh.nu *
#use pwd-overlay.nu *
#use direnv.nu *
#use completion-generator.nu *
use refine.nu
use comma/main.nu *
use comma/utils.nu *
#use task.nu *

use network.nu *
use setup.nu *
use history-utils.nu *
use resolvenv.nu
use nvim.nu *

use power/power.nu
    use power/lib/git.nu *
    power inject 0 1 {source: git,   color: '#504945'}
    use power/lib/kube.nu *
    power inject 1 2 {source: kube,  color: '#504945'} {
        context: cyan
    } {
        reverse: true
        separator: '@'
    }
    use power/lib/utils.nu *
    # power inject 0 1 {source: atuin, color: '#404040'}
    power set time null { style: compact }
power init

if (which atuin | is-not-empty) {
    source atuin.nu
}

const plugin_query = ($nu.current-exe | path dirname | path join (
    if $nu.os-info.family == 'windows' { 'nu_plugin_query.exe' } else { 'nu_plugin_query' }
))
register $plugin_query


########################################
const USRCFG = '~/.nu'
const USRCFG = if ($USRCFG | path expand | path exists) {
    $USRCFG
} else { 'dummy.nu' }
source $USRCFG
########################################

use __prefer_alt.nu prefer_alt_env
prefer_alt_env $env.PREFER_ALT?
