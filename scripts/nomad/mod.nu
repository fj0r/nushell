def cmpl-job [] {
    nomad job status | from ssv -a | get ID
}

def list-alloc [job] {
    mut f = false
    mut r = []
    for x in (nomad job status $job | lines) {
        if $f {
            $r ++= [$x]
        } else {
            if $x == 'Allocations' {
                $f = true
            }
        }
    }
    $r | str join (char newline) | from ssv -a
}

def cmpl-alloc [context] {
    use argx
    let ctx = $context | argx parse
    list-alloc $ctx.pos.job
    | each {|x|
        {
            value: $x.ID
            description: ($x | reject ID | values | str join (char tab))
        }
    }
    | { completions: $in, options: { sort: false } }
}

export def nomad-status [
    job?: string@cmpl-job
    alloc?: string@cmpl-alloc
] {
    if ($job | is-empty) {
        nomad job status | from ssv -a
    } else if ($alloc | is-empty) {
        nomad job status $job
    } else {
        nomad alloc logs -f $alloc
    }
}

export def nomad-fs [
    job:string@cmpl-job
    alloc:string@cmpl-alloc
    path?:path = .
] {
    nomad alloc fs $alloc $path
}

def cmpl-nomad-file [] {
  do -i {ls **/*.nomad} | append (do -i {ls **/*.hcl}) | get name
}

export def nomad-run [
    file:path@cmpl-nomad-file
    --dry-run(-d)
] {
    if $dry_run {
        nomad job plan $file
    } else {
        nomad job run $file
    }
}


