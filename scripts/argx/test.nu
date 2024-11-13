def test [a b x? ...y --cd(-c) --ef(-e):string -g -h:int --ij --lm] {}

"test -h 111 123 'asdf' --cd --ef sadf -g -h 222 x y z" | argx parse | to yaml


def --wrapped pa [
    --remove (-R): string
    --query (-q): string
    --list (-l): string
    ...args: string
] {}

'pa -l ' | argx parse | to yaml
'pa asdf' | argx parse | to yaml
