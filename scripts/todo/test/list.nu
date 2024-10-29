tga tag:a:b
let h = ta -t [tag:a:b] hastag
let h1 = ta -p $h.0 hastag1
let h2 = ta -p $h1.0 hastag2
let n = ta notag
let n1 = ta -p $n.0 notag1
let n2 = ta -p $n1.0 notag2
tt -t [:trash] $h2.0
tt -t [:trash] $n2.0
alias tx = tl #--debug
for c in [[cond, name, act];
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

