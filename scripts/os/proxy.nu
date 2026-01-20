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

export def --env "toggle proxy" [proxy?:string@cmpl-proxys --socks5(-s): string] {
    let has_set = ($env.https_proxy? | is-not-empty)
    let no_val = ($proxy | is-empty)
    if $has_set and $no_val {
        echo 'hide proxy'
        $env.http_proxy = null
        $env.https_proxy = null
        $env.all_proxy = null
    } else {
        let proxy = if ($proxy | is-empty) {
            'http://127.0.0.1:7890'
        } else {
            $proxy
        }
        echo $'set proxy ($proxy)'
        $env.http_proxy = $proxy
        $env.https_proxy = $proxy
        $env.all_proxy = if ($socks5 | is-empty) {
            $proxy
            | url parse
            | update scheme socks5
            | update port {|x| ($x.port | into int) + 1 }
            | url join
        } else {
            $socks5
        }
    }
    $env.no_proxy = 'localhost,127.0.0.1'
}
