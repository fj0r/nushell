export-env {
    $env.comma_action = {}
}

export def --env action [path action opts] {
    let path = if ($path | describe -d).type == list {
        $path
    } else {
        $path | split row -r '\s+'
    }

    for p in ($path | range ..-2) {
        $env.comma_action = (
            $env.comma_action | upsert $p {}
        )
    }
    {|a,s|
        do $action $a $s $env.comma_index
    }
}

