export alias site-mirror = wget -m -k -E -p -np -e robots=off

export def ns [] {
    netstat -aplnetu
    | awk '(NR>2)'
    | parse -r '(?P<proto>\w+) +(?P<recv>[0-9]+) +(?P<send>[0-9]+) +(?P<local>[0-9.]+):(?P<port>[0-9]+) +(?P<foreign>[0-9.:]+):(?P<f_port>[0-9]+) +(?P<state>\w+) +(?P<user>[0-9]+) +(?P<inode>[0-9]+) +(?P<program>.+)'
}

def "nu-complete proxys" [] {
    [
        'http://localhost:7890'
        $"http://(hostname -I | split row ' ' | get 0):7890"
    ]
}

export def-env "toggle proxy" [proxy?:string@"nu-complete proxys"] {
    let has_set = ($env | has 'http_proxy')
    let no_val = ($proxy | is-empty)
    let proxy = if $has_set and $no_val {
                echo 'hide proxy'
                $nothing
            } else {
                let p = if ($proxy|is-empty) {
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

