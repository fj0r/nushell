export def suspend [] {
    sudo bash -c 'echo "mem" > /sys/power/state'
}

def cmp-fs [] {
    let c = ^df -h
    | lines
    | slice 1..
    | split column -r '\s+' fs size used avail percent mount
    | where {|x| ($x.fs | str starts-with '/') and ($x.mount | path split | get 1?) in ['run', 'media'] }
    | each {|x|
        { value: $x.fs, description: $"($x.size)\t($x.mount)" }
    }
    | reverse
    { completions: $c, options: { sort: false, partial: false } }
}

export def eject-disk [fs :string@cmp-fs] {
    udisksctl unmount -b $fs
    mut d = ""
    for i in -2..-4 {
        let $a = $fs | str substring ..$i
        if ($a | path exists) {
            $d = $a
            break
        }
    }
    if ($d | is-not-empty ) and ([y n] | input list $"Power off ($d)?") == 'y' {
        udisksctl power-off -b $d
    }
}
