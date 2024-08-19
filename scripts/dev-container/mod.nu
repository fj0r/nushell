export def "docker registry created" [
    url: string
    repo: string
    tag: string
] {
    let header = if ($env.REGISTRY_TOKEN? | is-not-empty) {
        ["Authorization" $"Basic ($env.REGISTRY_TOKEN)"]
    } else {
        []
    }
    | append ['Accept' 'application/vnd.oci.image.manifest.v1+json']
    print $"($url)/v2/($repo)/manifests/($tag)"
    let d = http get -H $header $"($url)/v2/($repo)/manifests/($tag)"
    | from json
    | get config.digest
    http get -H $header $"($url)/v2/($repo)/blobs/($d)"
    | from json
    | get created
    | into datetime
}

export def 'docker proj base' [
    url: string
    repo: string
    manifest: string
    base: string = 'python:3.11-bookworm'
    workdir: string = '/app'
    scripts: list<string> = []
    cmd: string = ''
] {
    let f = [
        $"FROM ($base)"
        $"ENV PYTHONUNBUFFERED=x"
        $""
        $"WORKDIR ($workdir)"
        $"COPY ($manifest) ."
        $"RUN set -eux \\"
        ...($scripts | each {|x|
                let p = if ($x | str trim -l | str starts-with "|") { "  " } else { '; ' }
                $"  ($p)($x) \\"
            })
        $"  ;"
        $""
        $"CMD ($cmd)"
    ] | str join (char newline)
    print $"(ansi grey)($f)(char newline)------(ansi reset)"
    let t = $"($url)/($repo):_"
    $f | ^$env.docker-cli build -f - -t $t .
    ^$env.docker-cli push $t
}

export def 'docker proj build' [
    url: string
    repo: string
    manifest: string = 'packages.json'
    base: string = 'python:3.11-bookworm'
    scripts: list<string> = []
    cmd: string = ''
] {
    let n = date now | format date "%Y-%m-%d %H:%M:%S"
    let t = git log --reverse -n 1 --pretty=%h»¦«%s | split row '»¦«'
    let i = $"($url)/($repo):($n)"
    pp $env.docker-cli build ...[
        --build-arg $"CI_PIPELINE_BEGIN='($n)'"
        --build-arg $"CI_COMMIT_TITLE='($t.1)'"
        --build-arg $"CI_COMMIT_SHA='($t.0)'"
        --build-arg $"BASE_IMAGE='($url)/($repo):_'"
        -f Dockerfile
        -t $i
    ] .
    ^$env.docker-cli push $i
    ^$env.docker-cli rmi $i
}

export def 'main' [...args] {
    print $args
}
