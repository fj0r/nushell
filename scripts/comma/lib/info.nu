export def main [tbl format?: string = 'tree'] {
    let _ = $env.comma_index
    use resolve.nu
    let scope = resolve scope [] (resolve comma 'comma_scope') []
    use tree.nu
    let cb = {|pth, g, node, _|
        let level = ($pth | length)
        let description = if $format == 'table' {
            $g | filter { $in | is-not-empty } | str join ' | '
        } else {
            $g | last
        }
        let path = $pth | last
        let command = $pth | str join ' '
        {
            level: $level
            path: $path
            command: $command
            description: $description
        }
    }
    match $format {
        table => {
            $tbl | tree map $cb 'get_desc' $scope | select command description
        }
        tree => {
            for i in ($tbl | tree map $cb 'get_desc' $scope --with-branch) {
                let d = if ($i.description | is-empty) {
                    ''
                } else {
                    $"(char tab)(ansi grey)# ($i.description)(ansi reset)"
                }
                print $"('' | fill -c '    ' -w ($i.level - 1))($i.path)($d)"
            }
        }
        markdown => {
            for i in ($tbl | tree map $cb 'get_desc' $scope --with-branch) {
                print $"('' | fill -c '#' -w ($i.level)) ($i.path)"
                print $i.description
                print (char newline)
            }
        }
    }
}
