export def qutebrowser-open [...url] {
    let m = {
        args: [...$url]
        target_arg: null
        version: "3.3.1"
        protocol_version: 1
        cwd: $env.PWD
    }
    | to json -r
    let f = $"($env.XDG_RUNTIME_DIR)/qutebrowser/ipc-($env.USER | hash md5)"
    if ($f | path exists) {
        let u = $"UNIX-CONNECT:($f)"
        bash -c $"echo '($m)' | socat - ($u)"
    } else {
        bash -c $"nohup qutebrowser ($url | str join ' ') 2>&1 &"
    }
}
