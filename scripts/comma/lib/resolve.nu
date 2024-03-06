def wid [] {
    $env.PWD | path split | range 1.. | str join ':'
}

def dbg [a b] {
    if ($env.comma_debug? | is-not-empty) {
        let _ = $env.comma_index
        do $_.tips $a $b
        #print -e $env.comma_cache
    }
}

# FIXME:
export def --env comma_get_cache [key, act] {
    if $key in $env.comma_cache {
        $env.comma_cache | get $key
    } else {
        #dbg "miss cache" $key
        let r = do $act
        $env.comma_cache = ($env.comma_cache | upsert $key $r)
        $r
    }
}

export def scope [args, vars, flts] {
    let start = date now
    mut vs = {}
    mut cpu = []
    mut flt = {}
    let _ = $env.comma_index
    for i in ($vars | transpose k v) {
        if ($i.v | describe -d).type == 'record' {
            if $_.cpu in $i.v {
                $cpu ++= {k: $i.k, v: ($i.v | get $_.cpu)}
            } else if $_.flt in $i.v {
                $flt = ($flt | merge {$i.k: ($i.v | get $_.flt)} )
            } else {
                $vs = ($vs | merge {$i.k: $i.v})
            }
        } else {
            $vs = ($vs | merge {$i.k: $i.v})
        }
    }
    for i in $cpu {
        $vs = ($vs | merge {$i.k: (do $i.v $args $vs)} )
    }
    for i in ($flts | default []) {
        if $i in $flt {
            let fr = do ($flt | get $i) $args $vs
            let fr = if ($fr | describe -d).type == 'record' { $fr } else { {} }
            $vs = ($vs | merge $fr)
        } else {
            error make -u {msg: $"filter `($i)` not found" }
        }
    }
    dbg "resolve scope" ((date now) - $start)
    $vs
}


export def comma [key = 'comma'] {
    let start = date now
    let _ = $env.comma_index
    let r = if ($env | get $key | describe -d).type == 'closure' {
        comma_get_cache $"resolve-($key)::(wid)" { do ($env | get $key) $_ }
    } else {
        $env | get $key
    }
    dbg $"resolve comma ($key)" ((date now) - $start)
    $r
}
