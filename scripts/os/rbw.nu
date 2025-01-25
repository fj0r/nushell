def comp [ctx] {
    let pat = $ctx | argx parse | get pos.pattern
    rbw search $pat | lines | each {
        let p = $in | split row '/'
        let p = if ($p | length) > 1 {
            [$p.0 $p.1]
        } else {
            ['' $p.0]
        }
        let i = $p.1 | split row '@'
        let i = if ($i | length) > 1 {
            [$i.0, $i.1]
        } else {
            ['', $i.0]
        }
        [$p.0 ...$i]
    }
}

def comp-host [ctx] {
    comp $ctx | each { $in | last } | uniq
}

def comp-user [ctx] {
    comp $ctx | each {
        let x = $in
        { value: $x.1, description: $x.0 }
    }
}

export def rbws [
    pattern:string@comp-host
    user:string@comp-user
] {
    rbw get $pattern $user
    rbw code $pattern $user
}
