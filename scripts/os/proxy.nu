export def common-ips [] {
    let addr = ip-route
    mut r = {
        loopback:  'localhost'
        gateway: $addr.gateway.0
        lan: $addr.src?.0?
    }
    let cn = $addr | where dev =~ '(docker|podman|nerdctl)'
    if ($cn | is-not-empty) {
        $r.container = $cn.src.0
    }
    $r
}

def cmpl-proxys [context: string, offset: int] {
    let pre = $context | str substring ('toggle proxy ' | str length)..
    if ($context | str ends-with ':') {
        [7890 7891 1080] | each {|x| $"($pre)($x)"}
    } else if ($context | str ends-with '/') {
        let a = common-ips | transpose description value
        $a | each {|x|
            $x | update value $"($pre)($x.value):"
        }
    } else {
        ['socks5://' 'socks5h://' 'http://'  'https://']
    }
}

export def --env "toggle proxy" [proxy?:string@cmpl-proxys] {
    let has_set = ($env.https_proxy? | is-not-empty)
    let no_val = ($proxy | is-empty)
    if $has_set and $no_val {
        echo 'hide proxy'
        {
            http_proxy: null
            https_proxy: null
            all_proxy: null
        }
        | load-env
    } else {
        let proxy = if ($proxy | is-empty) {
            'socks5://127.0.0.1:7891'
        } else {
            $proxy
        }
        echo $'set proxy ($proxy)'
        {
            http_proxy: $proxy
            https_proxy: $proxy
        }
        | load-env
        if ($proxy | url parse).scheme in [socks5 socks5h] {
            $env.all_proxy = $proxy
        }
    }
    $env.no_proxy = 'localhost,127.0.0.1'
}
