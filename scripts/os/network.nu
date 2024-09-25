export alias site-mirror = wget -m -k -E -p -np -e robots=off

export def ns [] {
    netstat -aplnetu
    | awk '(NR>2)'
    | parse -r '(?<proto>\w+) +(?<recv>[0-9]+) +(?<send>[0-9]+) +(?<local>[0-9.]+):(?<port>[0-9]+) +(?<foreign>[0-9.:]+):(?<f_port>[0-9]+) +(?<state>\w+) +(?<user>[0-9]+) +(?<inode>[0-9]+) +(?<program>.+)'
}


export def ip-route [] {
    ip route
    | lines
    | parse -r ([
        '(?<default>default via)?'
        '(?<gateway>[0-9\./]+)'
        'dev (?<dev>[\w\-]+)'
        'proto (?<proto>dhcp|kernel scope link)'
        'src (?<src>[0-9\.]+)'
    ] | str join '\s*')
}

