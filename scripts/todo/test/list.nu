tga tag:a:b
let th = tga hidden
let h = ta -t [tag:a:b] hastag
let h1 = ta -t [tag:a] hastag1
let h2 = ta -t [tag] hastag2
let n = ta notag
let n1 = ta notag1
let n2 = ta  notag2
tt -t [hidden] $h1.0
tt -t [hidden] $n1.0
todo-delete $h2.0
todo-delete $n2.0
alias tx = tl #--debug
for c in [[cond, name, act];
    ['', 'tl' { tx }]
    ['', 'toggle hidden', { todo-tag-hidden $th.0 }]
    ['', 'tl hidden' { tx }]
    ['FTT', 'tl --untagged', { tx --untagged }]
    ['FTF', tl, { tx }]
    ['FFT', 'tl tag --untagged', { tx --untagged  tag}]
    ['FFF', 'tl tag', { tx tag }]
    ['TTT', 'tl --untagged --all', { tx --all --untagged }]
    ['TTF', 'tl --all', { tx --all }]
    ['TFT', 'tl tag --untagged --all', { tx --all --untagged  tag}]
    ['TFF', 'tl tag --all', { tx --all tag }]
] {
    lg level 1 {c: $c.cond} $c.name
    do $c.act | print $in
}

