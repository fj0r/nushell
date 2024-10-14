# select image
export def image-select [name] {
    let n = $name | parse-img
    let imgs = (image-list)
    let fs = [image tag repo]
    for i in 2..0 {
        let r = $imgs | filter {|x|
            $fs | range 0..$i | all {|y| ($n | get $y) == ($x | get $y) }
        }
        if ($r | is-not-empty) {
            return ($r | sort-by -r created | first | get name)
        }
    }
    $name
}

export def dx [args image] {
    let image = if ($image | ststr starts-with ':') {
        let c = open $env.CONTCONFIG | get preset | where name == $image
        if ($c | is-empty) {
            $image | str substring 1..
        } else {
            $c.image
        }
    } else {
        $image
    }
}
