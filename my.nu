# env.nu
$env.ENV_CONVERSIONS = {
  "PATH": {
    from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
    to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
  }
  "Path": {
    from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
    to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
  }
  "LD_LIBRARY_PATH": {
    from_string: { |s| if ($s | is-empty) { [] } else { $s | split row (char esep) } }
    to_string: { |v| if ($v | is-empty) { "" } else { $v | path expand | str join (char esep) } }
  }
}


for path in [
    [$'($env.HOME)/.local/bin']
    (do -i {ls '/opt/*/bin' | get name})
    (do -i {ls $'($env.LS_ROOT)/*/bin' | get name})
] {
    if not ($path | is-empty) {
        $env.PATH = ($env.PATH
        | prepend ($path | where $it not-in ($env.PATH | split row (char esep))))
    }
}

$env.LD_LIBRARY_PATH = (if ($env.LD_LIBRARY_PATH? | is-empty) { [] } else { $env.LD_LIBRARY_PATH })
$env.LD_LIBRARY_PATH = (do -i {
    $env.LD_LIBRARY_PATH
    | prepend (
        ls ((stack ghc -- --print-libdir) | str trim)
        | where type == dir
        | get name
        )
})

$env.TERM = 'screen-256color'
$env.SHELL = 'nu'

$env.EDITOR = 'nuedit' # 'nvim'
if ($env.EDITOR == 'nuedit') and (not ($'($env.HOME)/.local/bin/nuedit' | path exists)) {
    mkdir $'($env.HOME)/.local/bin/'
    cp $'($nu.config-path | path dirname)/nuedit' $'($env.HOME)/.local/bin/nuedit'
}

# settings

$env.config.show_banner = false
$env.config.history.file_format = "sqlite"
$env.config.history.isolation = true
$env.config.table.mode = light

# config.nu

#use utils.nu
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
use dynamic-load.nu *
use direnv.nu *
use nvim.nu *
#use ime.nu *
use zellij.nu *

####use starship.nu *
use network.nu *
use setup.nu *
#source zoxide.nu

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

source atuin.nu

