def test [
    --lll(-l): list<string>
    a b x? ...y --cd(-c) --ef(-e):string='asdf' --xyz(-x):string -g
    -h:int=123 --ij --lm
    ] {}

let x = scope commands | where name == test | first
print ($x.signatures | table -e)
