export def fmt-date [] {
    $in | format date '%FT%H:%M:%S'
}

export def block-edit [temp --line:int] {
    let content = $in
    let tf = mktemp -t $temp
    $content | save -f $tf
    variants-edit $tf --line $line
    let c = open $tf --raw
    rm -f $tf
    $c
}

export def Q [...t] {
    let s = $t | str join '' | str replace -a "'" "''"
    $"'($s)'"
}

export def run [stmt] {
    open $env.SSH_STATE | query db $stmt
}
