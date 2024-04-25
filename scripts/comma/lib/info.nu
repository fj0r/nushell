export def main [tbl, format: string = 'tree', all: bool = false] {
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
    let o = if $format in ['table'] {
        $tbl | tree map $cb 'get_desc' $scope
    } else {
        $tbl | tree map $cb 'get_desc' $scope --with-branch
    }
    let o = if $all {
        $o
    } else {
        $o | filter {|x| $x.command | str starts-with '.' | not $in }
    }
    match $format {
        table => {
            $o | select command description
        }
        tree => {
            for i in $o {
                let d = if ($i.description | is-empty) {
                    ''
                } else {
                    $"(char tab)(ansi grey)# ($i.description)(ansi reset)"
                }
                print $"('' | fill -c '    ' -w ($i.level - 1))($i.path)($d)"
            }
        }
        markdown => {
            mut r = []
            for i in $o {
                $r ++= $"('' | fill -c '#' -w ($i.level)) ($i.path)"
                $r ++= $i.description
                $r ++= ''
            }
            $r | str join (char newline)
        }
    }
}
