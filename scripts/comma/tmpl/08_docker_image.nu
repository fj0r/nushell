'image'
| comma val null {
    base: 'node'
    middle: {
        name: 'base/node'
        script: [
            "npm install"
        ]
    }
    target: {
        name: 'node-app'
    }
}

'dev image middle'
| comma fun {|a,s,_|
    let f = [
        $"FROM ($s.image.base)"
        $"RUN set -eux \\"
        ...($s.image.middle.script | each {|x|
                let p = if ($x | str trim -l | str starts-with "|") { "  " } else { '; ' }
                $"  ($p)($x) \\"
            })
        '  ;'
    ]
    $f | save -f Dockerfile.base
    pp $env.docker-cli build -f Dockerfile.base -t $s.image.middle.name .
    rm -rf Dockerfile.base
    pp $env.docker-cli push $s.image.middle.name
}

'dev image build'
| comma fun {|a,s,_|
    let n = date now | format date "%Y-%m-%d %H:%M:%S"
    let t = git log --reverse -n 1 --pretty=%h»¦«%s | split row '»¦«'
    pp $env.docker-cli build ...[
        --build-arg $"CI_PIPELINE_BEGIN='($n)'"
        --build-arg $"CI_COMMIT_TITLE='($t.1)'"
        --build-arg $"CI_COMMIT_SHA='($t.0)'"
        --build-arg $"BASE_IMAGE='($s.image.middle.name)'"
        -f Dockerfile
        -t $s.image.target.name
    ] .
    pp $env.docker-cli push $s.image.target.name
}
