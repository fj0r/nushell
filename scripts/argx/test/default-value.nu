# run-and-watch -g scripts/argx/mod.nu { nu -c "use argx; source scripts/argx/test/default-value.nu" }


def xxx [a?:string='xxx' --bar(-b):path='adfsf' --xyz(-x)] {}

argx test 'xxx'
argx test -p 'xxx'
argx test -p 'xxx a'
argx test -p 'xxx a -b b -x'
