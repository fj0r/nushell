'. reload'
| comma fun {|a,s,_|
    let act = $a | str join ' '
    $', ($act)' | batch -i ',.nu'
} {
    watch: { glob: ",.nu", clear: true }
    completion: {|a,s|
        , -c ...$a
    }
    desc: "reload & run ,.nu"
}
