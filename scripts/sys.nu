def ns [] {
    netstat -aplnetu
    | awk '(NR>2)'
    | parse -r '(?P<proto>\w+) +(?P<recv>[0-9]+) +(?P<send>[0-9]+) +(?P<local>[0-9.]+):(?P<port>[0-9]+) +(?P<foreign>[0-9.:]+):(?P<f_port>[0-9]+) +(?P<state>\w+) +(?P<user>[0-9]+) +(?P<inode>[0-9]+) +(?P<program>.+)'
}
