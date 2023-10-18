# settings

$env.config.show_banner = false
$env.config.use_kitty_protocol = true
$env.config.history.file_format = "sqlite"
$env.config.history.isolation = true
$env.config.table.header_on_separator = true
$env.config.table.mode = compact #light compact
$env.config.table.padding.left = 0

# config.nu

#use utils.nu
use nvim.nu *
use after.nu *
use timelog.nu *
use zoxide-menu.nu *
use nushell.nu *
use sys.nu *
use common.nu *
use just.nu *
use mask.nu *
use git-cmp.nu *
use git.nu *
use ssh.nu *
use kubernetes.nu *
use docker.nu *
#use timeit.nu *
use sh.nu *
#use pwd-overlay.nu *
use direnv.nu *
#use ime.nu *
use zellij.nu *

####use starship.nu *
use network.nu *
use setup.nu *
source zoxide.nu

use power.nu
    use power_git.nu
    power inject 0 1 {source: git,   color: '#504945'}
    use power_kube.nu
    power inject 1 2 {source: kube,  color: '#504945'} {
        context: cyan
    } {
        reverse: true
        separator: '@'
    }
    use power_utils.nu
    # power inject 0 1 {source: atuin, color: '#404040'}
    power set time null { style: compact }
power init


# if not (which atuin | is-empty) {
#     source atuin.nu
# }

const USRCFG = '~/.nu'
const USRCFG = if ($USRCFG | path expand | path exists) {
    $USRCFG
} else { 'dummy.nu' }
source $USRCFG

const plugin_query = ($nu.current-exe | path dirname | path join 'nu_plugin_query')
register $plugin_query
