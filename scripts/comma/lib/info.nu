export def main [tbl] {
    let _ = $env.comma_index
    use resolve.nu
    let scope = resolve scope [] (resolve comma 'comma_scope') []
    use tree.nu
    let cb = {|pth, g, node, _|
        let indent = ($pth | length)

        let description = $g
        | filter {|x| $x | is-not-empty }
        | str join ' | '
        let command = $pth
        | str join ' '
        {
            command: $command
            description: $description
        }
    }
    $tbl | tree map $cb null $scope
}
