# run-and-watch -g scripts/argx/mod.nu { nu -c "use argx; source scripts/argx/test/default-value.nu" }


def xxx [x: string = 'xyz' a?:string='xxx' --bar(-b):path='adfsf' --xyz(-x)
    ...res:string
] {}

argx test 'xxx'
argx test -p 'xxx'
argx test -p 'xxx a'
argx test -p 'xxx a -b b -x'
argx test -p 'xxx a -b b -x u v w z 1 2 3 4 5 6 '
