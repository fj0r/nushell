const __dyn_load = if ('~/.env.nu' | path exists) { '~/.env.nu' }
source $__dyn_load
source env.nu

# settings
$env.config.show_banner = 'short'
$env.config.use_kitty_protocol = true
$env.config.filesize.unit = 'metric'
$env.config.datetime_format.normal = '%m/%d/%y %H:%M:%S'
$env.config.datetime_format.table = '%m/%d/%y %H:%M:%S'
$env.config.history.file_format = "sqlite"
$env.config.history.isolation = true
$env.config.completions.algorithm = 'fuzzy' # prefix|substring|fuzzy
$env.config.completions.partial = false
$env.config.table.header_on_separator = true
$env.config.table.mode = 'light' # light|compact
$env.config.table.padding = 0
$env.config.color_config.hints = 'gray'

if not ($nu.data-dir | path exists) { mkdir $nu.data-dir }
if not ($nu.cache-dir | path exists) { mkdir $nu.cache-dir }

source plugin.nu

const __dyn_load = if ('~/.nu' | path exists) { '~/.nu' }
source $__dyn_load

source keymaps.nu


$env.config.hooks.pre_prompt = ($env.config.hooks.pre_prompt? | default [])
$env.config.hooks.pre_execution = ($env.config.hooks.pre_execution? | default [])
$env.config.hooks.pre_execution ++= [{
    if ((commandline) | str starts-with ' ') {
      $env.DELETE_FROM_HISTORY = 1
    }
}]

$env.config.hooks.pre_prompt ++= [{
  if ($env.DELETE_FROM_HISTORY? != null) {
    print $"(ansi grey)Command executed but not saved to history \(leading space detected\).(ansi reset)"
    open $nu.history-path
    | query db $"DELETE FROM history WHERE command_line LIKE ' %'"
    hide-env DELETE_FROM_HISTORY
  }
}]
