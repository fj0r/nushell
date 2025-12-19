export def "oci wrap" [
    image
    --author (-a): string = ""
    cb: closure
] {
    if (whoami) != 'root' {
        print 'run `buildah unshare` first'
        return
    }
    let working_container = buildah from scratch
    lg level 1 { working_container: $working_container }
    let mountpoint = buildah mount $working_container
    lg level 1 { mountpoint: $mountpoint }
    do -i $cb $mountpoint
    buildah config --author $author --label "type=image-volume" $working_container
    buildah unmount $working_container
    lg level 1 'unmount'
    buildah commit $working_container $image
    lg level 3 commit $image
    if ([y n] | input list $'push `($image)` now?') == 'y' {
        container push $image
    }
}

use complete.nu *
use base.nu *
export def "oci unwrap" [
    image: string@cmpl-docker-images
    path
] {
    let c = container create $image
    do -i {
        container export $c | tar -xC $path
    }
    print $"(ansi grey)clean ...(ansi reset)"
    container rm $c
}
