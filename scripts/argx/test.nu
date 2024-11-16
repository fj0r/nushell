# run-and-watch -g scripts/argx/mod.nu { nu -c "use argx; source scripts/argx/test.nu" }
def test-parse [$s -p] {
    print $"(ansi yellow)($s)(ansi reset)"
    let r = $s | argx parse --pos=$p | to yaml
    print $"(ansi grey)($r)(ansi reset)"
}
def test [
    --lll(-l): list<string>
a b x? ...y --cd(-c) --ef(-e):string --xyz(-x):string -g -h:int --ij --lm] {}

test-parse "test -h 111 123 'asdf' --cd --ef sadf -g -h 222 x y z -x xyz -l [a b c]"


def --wrapped pa [
    --remove (-R): string
    --query (-q): int
    --list (-l): string
    --aaa
    -a
    xx: string
    b: int
    m: record
    n: closure
    ...args
] {}

test-parse 'pa -l adf m 123 {a: b, c: 1} { ls }  --query 23 -a  1 2 3' -p
test-parse 'pa asdf 123 -l asdf b b  --query 23 -a'

def xx [
    a: string
    b: int
    c: bool
    d?: string
    ...ad
] {}

test-parse -p 'xx a 1 true x y z'
