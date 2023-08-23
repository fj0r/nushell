# settings

$env.config.show_banner = false
$env.config.history.file_format = "sqlite"
$env.config.history.isolation = true
$env.config.table.mode = light
$env.config.table.header_on_separator = true

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
use git-cmp.nu *
use git.nu *
use ssh.nu *
use kubernetes.nu *
use docker.nu *
#use timeit.nu *
use sh.nu *
#use pwd-overlay.nu *
#use dynamic-load.nu *
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
    power inject 0 1 {source: atuin, color: '#404040'}
    power set time $nothing { short: false }
power init


if not (which atuin | is-empty) {
    source atuin.nu
}

const ucf = '~/.nu'
if ($ucf | path expand | path exists) {
    #source $ucf
}
