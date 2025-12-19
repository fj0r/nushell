export def "bud img" [] {
    buildah images
    | from ssv -a
    | rename repo tag id created size
    | upsert size { |i| $i.size | into filesize }
}

export def "bud ls" [] {
    buildah list
    | from ssv -a
    | rename id builder image-id image container
}

export def "bud ps" [] {
    buildah ps
    | from ssv -a
    | rename id builder image-id image container
}

def cmpl-bud-ps [] {
    bud ps
    | select 'CONTAINER ID' "CONTAINER NAME"
    | rename value description
}

export def "bud rm" [
    id: string@cmpl-bud-ps
] {
    buildah rm $id
}

export def "bud data" [
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
}
