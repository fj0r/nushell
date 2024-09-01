'image'
| comma val null {
    mid: {
        name: 'mid/py'
        base: 'python:3.11-bookworm'
        workdir: '/app'
        manifest: 'requirements.txt'
        script: [
            "pip install --break-system-packages --no-cache-dir -r requirements.txt"
        ]
        cmd: ["fastapi", "run", "main.py"]
    }
    target: {
        name: 'python-app'
    }
}

'dev image mid'
| comma fun {|a,s,_|
    let m = $s.image.mid
    let f = [
        $"FROM ($m.base)"
        $"ENV PYTHONUNBUFFERED=x"
        $""
        $"WORKDIR ($m.workdir)"
        $"COPY ($m.manifest) ."
        $"RUN set -eux \\"
        ...($m.script | each {|x|
                let p = if ($x | str trim -l | str starts-with "|") { "  " } else { '; ' }
                $"  ($p)($x) \\"
            })
        $"  ;"
        $""
        $"CMD ($m.cmd | to json -r)"
    ] | str join (char newline)
    print $"(ansi grey)($f)(char newline)------(ansi reset)"
    $f | ^$env.CONTCTL build -f - -t $m.name .
    pp $env.CONTCTL push $m.name
}

'dev image build'
| comma fun {|a,s,_|
    let n = date now | format date "%Y-%m-%d %H:%M:%S"
    let t = git log --reverse -n 1 --pretty=%h»¦«%s | split row '»¦«'
    pp $env.CONTCTL build ...[
        --build-arg $"CI_PIPELINE_BEGIN='($n)'"
        --build-arg $"CI_COMMIT_TITLE='($t.1)'"
        --build-arg $"CI_COMMIT_SHA='($t.0)'"
        --build-arg $"BASE_IMAGE='($s.image.mid.name)'"
        -f Dockerfile
        -t $s.image.target.name
    ] .
    pp $env.CONTCTL push $s.image.target.name
}
