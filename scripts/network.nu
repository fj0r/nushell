export alias site-mirror = wget -m -k -E -p -np -e robots=off

export def ns [] {
    netstat -aplnetu
    | awk '(NR>2)'
    | parse -r '(?<proto>\w+) +(?<recv>[0-9]+) +(?<send>[0-9]+) +(?<local>[0-9.]+):(?<port>[0-9]+) +(?<foreign>[0-9.:]+):(?<f_port>[0-9]+) +(?<state>\w+) +(?<user>[0-9]+) +(?<inode>[0-9]+) +(?<program>.+)'
}

export def common-ips [] {
    let addr = ip route | lines | get 0 | parse -r 'default via (?<gateway>[0-9\.]+) dev (?<dev>\w+)( proto dhcp src (?<lan>[0-9\.]+))?'
    return {
        loopback:  'localhost'
        gateway: $addr.gateway.0
        lan: $addr.lan?.0?
    }
}

def "nu-complete proxys" [context: string, offset: int] {
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

export def --env "toggle proxy" [proxy?:string@"nu-complete proxys"] {
    let has_set = ($env.https_proxy? | is-not-empty)
    let no_val = ($proxy | is-empty)
    let proxy = if $has_set and $no_val {
                echo 'hide proxy'
                null
            } else {
                let p = if ($proxy | is-empty) {
                            'http://localhost:7890'
                        } else {
                            $proxy
                        }
                echo $'set proxy ($p)'
                $p
            }
    $env.http_proxy = $proxy
    $env.https_proxy = $proxy
}

