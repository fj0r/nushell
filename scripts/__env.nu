# env.nu
$env.ENV_CONVERSIONS.LD_LIBRARY_PATH = {
    from_string: { |s| if ($s | is-empty) { [] } else { $s | split row (char esep) } }
    to_string: { |v| if ($v | is-empty) { "" } else { $v | path expand | str join (char esep) } }
}

if $nu.os-info.family == 'windows'  {
    $env.HOME = $env.HOMEPATH
}

def --env merge-path [path] {
    let windows = $nu.os-info.family == 'windows'
    mut ep = if $windows { $env.Path } else { $env.PATH }
    #mut ep = $path | split row (char esep)
    let path = $path | each { glob $in } | flatten
    for x in $path {
        if $x not-in $ep {
            $ep = ($ep | prepend $x)
        }
    }
    if $windows { $env.Path = $ep } else { $env.PATH = $ep }
}

merge-path [
    $'($env.HOME)/.local/bin'
    '/opt/*/bin'
    $'($env.LS_ROOT?)/*/bin'
]

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
for s in ['/usr/local/bin', '/usr/bin'] {
    let p = [$s, 'nu'] | path join
    if (which $p | is-not-empty) {
        $env.SHELL = $p
        break
    }
}

$env.PREFER_ALT = '1'

$env.EDITOR = 'nvim' # 'nuedit'

if ($env.EDITOR == 'nuedit') and (not ($'($env.HOME)/.local/bin/nuedit' | path exists)) {
    mkdir $'($env.HOME)/.local/bin/'
    cp $'($nu.config-path | path dirname)/nuedit' $'($env.HOME)/.local/bin/nuedit'
}

