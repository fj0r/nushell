def test [a b x? ...y --cd(-c) --ef(-e):string -g -h:int --ij --lm] {}

"test -h 111 123 'asdf' --cd --ef sadf -g -h 222 x y z" | argx parse | to yaml
