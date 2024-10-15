'. nu'
| comma fun {|a,s| nu $a.0 } {
    watch: { glob: '*.nu', clear: true }
    completion: { ls *.nu | get name }
    desc: "develop a nu script"
}

'. py'
| comma fun {|a,s| python3 $a.0 } {
    watch: { glob: '*.py', clear: true }
    completion: { ls *.py| get name }
    desc: "develop a python script"
}

