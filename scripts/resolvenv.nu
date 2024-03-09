export def regex_match [val, tbl] {
    for i in ($tbl | transpose k v | where k != '_') {
        if ($val | find -ir $i.k | is-not-empty) {
            return (do $i.v $val)
        }
    }
    if ('_' in $tbl) {
        return (do ($tbl | get '_') $val)
    }
}

export def regex_match_record [val, tbl] {
    mut ev = {}
    for i in ($tbl | transpose k v | where k != '_') {
        if ($val | find -ir $i.k | is-not-empty) {
            $ev = $i.v
            break
        }
    }
    if ($ev | is-empty) and ('_' in $tbl) {
        $ev = ($tbl | get '_')
    }
    $ev
}


export def 'wifi ssid' [dev=wlan0] {
    if (which iw | is-empty) {
        print -e 'please install iw'
    } else {
        iw dev $dev link | awk '/SSID/{print $2}'
    }
}

# Connect to a special wifi to perform corresponding operations (wifi select) or set environment variables (wifi env).
# For example, use an external monitor in the workplace and set different scaling parameters (this example may not be very appropriate, and the monitor should be detected)
# ```
# use wifi-env.nu *
# wifi env wlan0 {
#     home-wlan: {
#         NEOVIM_LINE_SPACE: '2'
#         NEOVIDE_SCALE_FACTOR:  '0.5'
#     }
#     workspace-wlan: {
#         NEOVIM_LINE_SPACE: '1'
#         NEOVIDE_SCALE_FACTOR:  '0.7'
#     }
#     _: {
#         NEOVIM_LINE_SPACE: '0'
#         NEOVIDE_SCALE_FACTOR:  '0.5'
#     }
# }
# ```
export def 'wifi select' [dev tbl] {
    let ssid = wifi ssid $dev
    regex_match $ssid $tbl
}

export def --env 'wifi env' [dev tbl] {
    let ssid = wifi ssid $dev
    regex_match_record $ssid $tbl | load-env
}
