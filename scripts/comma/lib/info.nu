export def main [tbl] {
    let _ = $env.comma_index
    use tree.nu
    let bh = {|node, _|
        if $_.dsc in $node {
            $node | get $_.dsc
        } else {
            ''
        }
    }
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
    $tbl
    | tree map $cb $bh
}
