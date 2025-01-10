# run-and-watch -g scripts/argx/mod.nu { nu -c "use argx; source scripts/argx/test/default-value.nu" }

def test-parse [$s -p] {
    print $"(ansi yellow)($s)(ansi reset)"
    let r = $s | argx parse --pos=$p | to yaml
    print $"(ansi grey)($r)(ansi reset)"
}

def xxx [a?:string='xxx' --bar(-b):path='adfsf' --xyz(-x)] {}

test-parse 'xxx'
test-parse -p 'xxx'
test-parse -p 'xxx a'
test-parse -p 'xxx a -b b -x'
