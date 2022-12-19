# Nushell Environment Config File

def create_left_prompt [] {
    let path_segment = if (is-admin) {
        $"(ansi red_bold)($env.PWD)"
    } else {
        $"(ansi green_bold)($env.PWD)"
    }

    $path_segment
}

def create_right_prompt [] {
    let time_segment = ([
        (date now | date format '%m/%d/%Y %r')
    ] | str join)

    $time_segment
}

# Use nushell functions to define your right and left prompt
let-env PROMPT_COMMAND = { create_left_prompt }
let-env PROMPT_COMMAND_RIGHT = { create_right_prompt }

# The prompt indicators are environmental variables that represent
# the state of the prompt
let-env PROMPT_INDICATOR = { "〉" }
let-env PROMPT_INDICATOR_VI_INSERT = { ": " }
let-env PROMPT_INDICATOR_VI_NORMAL = { "〉" }
let-env PROMPT_MULTILINE_INDICATOR = { "::: " }

# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running external commands (to_string)
# Note: The conversions happen *after* config.nu is loaded
let-env ENV_CONVERSIONS = {
  "PATH": {
    from_string: { |s| $s | split row (char esep) | path expand -n }
    to_string: { |v| $v | path expand -n | str join (char esep) }
  }
  "Path": {
    from_string: { |s| $s | split row (char esep) | path expand -n }
    to_string: { |v| $v | path expand -n | str join (char esep) }
  }
  "LD_LIBRARY_PATH": {
    from_string: { |s| if ($s | is-empty) { [] } else { $s | split row (char esep) } }
    to_string: { |v| if ($v | is-empty) { "" } else { $v | path expand | str join (char esep) } }
  }
}

# Directories to search for scripts when calling source or use
#
# By default, <nushell-config-dir>/scripts is added
let-env NU_LIB_DIRS = [
    ($nu.config-path | path dirname | path join 'scripts')
]

# Directories to search for plugin binaries when calling register
#
# By default, <nushell-config-dir>/plugins is added
let-env NU_PLUGIN_DIRS = [
    ($nu.config-path | path dirname | path join 'plugins')
]

# To add entries to PATH (on Windows you might use Path), you can use the following pattern:
let-env PATH = ($env.PATH
    | split row (char esep)
    | prepend (ls /opt/*/bin | get name)
    | prepend $'($env.HOME)/.local/bin'
    )

let-env LD_LIBRARY_PATH = if 'LD_LIBRARY_PATH' in (env).name { $env.LD_LIBRARY_PATH } else { [] }
let-env LD_LIBRARY_PATH = do -i {
    $env.LD_LIBRARY_PATH
    | prepend (
        ls ((ghc --print-libdir) | str trim)
        | where type == dir
        | get name
        )
}

let-env TERM = 'tmux-256color'

let-env EDITOR = 'nvim' # 'nuedit'
let-env SHELL = 'nu' # for zellij
let-env NVIM_PRESET = if 'NVIM_PRESET' in (env).name { $env.NVIM_PRESET } else { 'x' }


let-env LS_COLORS = 'no=0;38;15:rs=0:di=1;34:ln=01;35:mh=00:pi=40;33:so=1;38;211:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=30;42:st=37;44:ex=1;30;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.lz=01;31:*.xz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.axv=01;35:*.anx=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=01;33:*.au=01;33:*.flac=01;33:*.mid=01;33:*.midi=01;33:*.mka=01;33:*.mp3=01;33:*.mpc=01;33:*.ogg=01;33:*.ra=01;33:*.wav=01;33:*.axa=01;33:*.oga=01;33:*.spx=01;33:*.xspf=01;33:*.doc=01;91:*.ppt=01;91:*.xls=01;91:*.docx=01;91:*.pptx=01;91:*.xlsx=01;91:*.odt=01;91:*.ods=01;91:*.odp=01;91:*.pdf=01;91:*.tex=01;91:*.md=01;91:'
