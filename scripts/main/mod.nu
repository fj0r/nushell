const __dyn_load = if ('~/.env.nu' | path exists) { '~/.env.nu' } else { 'dummy.nu' }
source $__dyn_load
source env.nu

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

if not ($nu.data-dir | path exists) { mkdir $nu.data-dir }
if not ($nu.cache-dir | path exists) { mkdir $nu.cache-dir }

source plugin.nu

const __dyn_load = if ('~/.nu' | path exists) { '~/.nu' } else { 'dummy.nu' }
source $__dyn_load

source keymaps.nu

