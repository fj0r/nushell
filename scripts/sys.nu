def ns [] {
    netstat -aplnetu
    | awk '(NR>2)'
    | parse -r '(?P<proto>\w+) +(?P<recv>[0-9]+) +(?P<send>[0-9]+) +(?P<local>[0-9.]+):(?P<port>[0-9]+) +(?P<foreign>[0-9.:]+):(?P<f_port>[0-9]+) +(?P<state>\w+) +(?P<user>[0-9]+) +(?P<inode>[0-9]+) +(?P<program>.+)'
}

def-env "toggle proxy" [] {
    let p = if (do -i { $env.http_proxy } | empty?) {
                echo 'set proxy'
                'http://localhost:9876'
            } else {
                echo 'hide proxy'
                ''
            }
    let-env http_proxy = $p
    let-env https_proxy = $p
}
