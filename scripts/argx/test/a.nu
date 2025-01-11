# run-and-watch -g scripts/argx/mod.nu { nu -c "use argx; source scripts/argx/test/a.nu" }
def test [
    --lll(-l): list<string>
a b x? ...y --cd(-c) --ef(-e):string --xyz(-x):string -g -h:int --ij --lm] {}

argx test "test -h 111 123 'asdf' --cd --ef sadf -g -h 222 x y z -x xyz -l [a b c]"


def --wrapped pa [
    --remove (-R): string
    --query (-q): int
    --list (-l): string
    --aaa
    -a
    xx: string
    b: int
    m: record
    n: list<int>
    ...args
] {}

argx test 'pa -l adf m 123 {a: b, c: 1} { ls }  --query 23 -a  1 2 3' -p
argx test 'pa asdf 123 -l asdf b b  --query 23 -a'
argx test 'pa asdf 11 {a: {b: {c: {d: 1}}}}'

def xx [
    a: string
    b: int
    c: bool
    d?: string
    ...ad
] {}

argx test -p 'xx a 1 true x y z xx f'
