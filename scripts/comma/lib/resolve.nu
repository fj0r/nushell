def wid [] {
    $env.PWD | path split | range 1.. | str join ':'
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

use lg.nu
use closure.nu
export def scope [args, vars, flts, --mode: string] {
    let start = date now
    mut vs = {}
    mut cpu = []
    mut flt = {}
    let _ = $env.comma_index
    for i in ($vars | transpose k v) {
        if ($i.v | describe -d).type == 'record' and (
            $_.cpu in $i.v or $_.flt in $i.v
        ) {
            if $_.cpu in $i.v {
                $cpu ++= {k: $i.k, v: ($i.v | get $_.cpu)}
            }
            if $_.flt in $i.v {
                $flt = ($flt | merge {$i.k: ($i.v | get $_.flt)} )
            }
        } else {
            $vs = ($vs | merge {$i.k: $i.v})
        }
    }
    for i in $cpu {
        # required arguments may not exist when completing
        # when the number of parameters is more than 2, it will be executed in non-main
        let cr = if $mode == 'main' or (closure parameters $i.v | length) > 2 {
            do $i.v $args $vs $mode
        }
        $vs = ($vs | merge {$i.k: $cr} )
    }
    for i in ($flts | default []) {
        if $i in $flt {
            let cl = $flt | get $i
            # required arguments may not exist when completing
            # when the number of parameters is more than 2, it will be executed in non-main
            let fr = if $mode == 'main' or (closure parameters $cl | length) > 2 {
                do $cl $args $vs $mode
            }
            let fr = if ($fr | describe -d).type == 'record' { $fr } else { {} }
            $vs = ($vs | merge $fr)
        } else {
            error make -u {msg: $"filter `($i)` not found" }
        }
    }
    lg dbg "resolve scope" ((date now) - $start)
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
    lg dbg $"resolve comma ($key)" ((date now) - $start)
    $r
}
