# env.nu
$env.NU_VENDOR_AUTOLOAD_DIR = [$nu.default-config-dir autoload] | path join

$env.ENV_CONVERSIONS.LD_LIBRARY_PATH = {
    from_string: { |s| if ($s | is-empty) { [] } else { $s | split row (char esep) } }
    to_string: { |v| if ($v | is-empty) { "" } else { $v | path expand | str join (char esep) } }
}

def --env merge-path [path] {
    let p = $path
    | each { glob $in }
    | flatten
    | filter {|x| $x not-in $env.PATH }
    for x in $p {
        $env.PATH = ($env.PATH | prepend $x)
    }
}


if $nu.os-info.family == 'windows'  {
    $env.HOME = $env.HOMEPATH
} else {
    merge-path [
        $'($env.HOME)/.cargo/bin'
        $'($env.HOME)/.ghcup/bin'
        $'($env.HOME)/.local/bin'
        '/opt/*/bin'
        $'($env.LS_ROOT?)/*/bin'
    ]
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
$env.EDITOR = 'nvim'
for s in ['/usr/local/bin', '/usr/bin'] {
    let p = [$s, 'nu'] | path join
    if (which $p | is-not-empty) {
        $env.SHELL = $p
        break
    }
}

$env.PREFER_ALT = '1'

