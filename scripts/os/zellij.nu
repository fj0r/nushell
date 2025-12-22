export def zellij-session [] {
    zellij list-sessions -n
    | lines
    | parse -r '^(?<name>[\w-]+) \[(?<time>.+)\]( \((?<status>.+)\))?'
    | select name time status
}

def cmpl-zellij-session [] {
    zellij-session
    | each {|x|
        { value: $x.name, describe: $"($x.status) -- ($x.time)" }
    }
}

export def zellij-enter [name: string@cmpl-zellij-session] {
    zellij attach --create $name
}

export def zellij-delete [name: string@cmpl-zellij-session] {
    zellij delete-session $name
}

export def --env zellij-cd [path?: string] {
    if ("ZELLIJ" in $env) {
        let dir_name = ($path | default $env.PWD | path basename)
        zellij action rename-tab $dir_name
    }
    if ($path | is-not-empty) {
        cd $path
    }
}

export-env {
    $env.config.keybindings ++= [
        {
            name: zellij_cd
            modifier: control
            keycode: enter
            mode: [emacs, vi_insert, vi_normal]
            event: [
                { edit: movetolinestart }
                { edit: insertstring value: 'zellij-cd '}
                { send: Enter }
            ]
        }
    ]
}

