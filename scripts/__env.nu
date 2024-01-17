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

if $nu.os-info.family == 'windows'  {
    $env.HOME = $env.HOMEPATH
}

for path in [
    [$'($env.HOME)/.local/bin']
    (do -i {ls '/opt/*/bin' | get name})
    (do -i {ls $'($env.LS_ROOT)/*/bin' | get name})
] {
    if not ($path | is-empty) {
        if $nu.os-info.family == 'windows'  {
            $env.Path = ($env.Path
            | prepend ($path | where $it not-in ($env.Path | split row (char esep))))
        } else {
            $env.PATH = ($env.PATH
            | prepend ($path | where $it not-in ($env.PATH | split row (char esep))))
        }
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
$env.SHELL = '/usr/bin/nu'

$env.EDITOR = 'nuedit' # 'nvim'
if ($env.EDITOR == 'nuedit') and (not ($'($env.HOME)/.local/bin/nuedit' | path exists)) {
    mkdir $'($env.HOME)/.local/bin/'
    cp $'($nu.config-path | path dirname)/nuedit' $'($env.HOME)/.local/bin/nuedit'
}

