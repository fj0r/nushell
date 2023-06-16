export def has [name] {
    $name in ($in | columns) and (not ($in | get $name | is-empty))
}

export alias site-mirror = wget -m -k -E -p -np -e robots=off

export def ns [] {
    netstat -aplnetu
    | awk '(NR>2)'
    | parse -r '(?P<proto>\w+) +(?P<recv>[0-9]+) +(?P<send>[0-9]+) +(?P<local>[0-9.]+):(?P<port>[0-9]+) +(?P<foreign>[0-9.:]+):(?P<f_port>[0-9]+) +(?P<state>\w+) +(?P<user>[0-9]+) +(?P<inode>[0-9]+) +(?P<program>.+)'
}

def "nu-complete proxys" [context: string, offset: int] {
    let cl = ('toggle proxy ' | str length)
    if $offset == $cl {
        ['socks5://' 'http://'  'https://']
    } else if ($context | str ends-with ':') {
        [7890 7891 1080] | each {|x| $"($context | str substring $cl..)($x)"}
    } else if ($context | str ends-with '/') {
        [
            {value: 'localhost', description: 'loopback'}
            {value: (ip route | lines | get 0 | split row ' ' | get 2), description: 'gateway'}
            (hostname -I | split row ' ' | filter {|x| ($x | str length) > 1} | each {|x| {value: $x, description: 'local'} })
        ] | flatten | each {|x|
            {value: $"($context | str substring $cl..)($x.value):", description: $x.description}
        }
    }
}

export def-env "toggle proxy" [proxy?:string@"nu-complete proxys"] {
    let has_set = ($env | has 'https_proxy')
    let no_val = ($proxy | is-empty)
    let proxy = if $has_set and $no_val {
                echo 'hide proxy'
                $nothing
            } else {
                let p = if ($proxy | is-empty) {
                            'http://localhost:7890'
                        } else {
                            $proxy
                        }
                echo $'set proxy ($p)'
                $p
            }
    let-env http_proxy = $proxy
    let-env https_proxy = $proxy
}

