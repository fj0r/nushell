## todo
- [ ] history-path
- [x] parse completions with `$nu.scope.commands`
    - `$nu.scope.commands | where name == ke | get signatures`
    - cache
- [x] kconf import : mask
    - [ ] diff server cert and prompt
- [ ] git
    - [ ]
- [ ] comma
    - [ ] run filter when completion
- [x] kubernetes independent kubectx & kubens
    - [ ] parse `kube diff` and modify filename
- [x] docker
    - [x] -v
    - [x] transform dis output
- [x] powerline
    - [x] proxy stat no effects in plain mode
    - [x] env hooks for regenerate thunks (def-env)
        - [x] NU_POWERLINE
        - [x] NU_UPPROMPT
        - [x] NU_PROMPT_SCHEMA
        - [x] MENU_MARKER_SCHEMA
        - [x] NU_PROMPT_GIT_FORMATTER


## migrate
- [x] Nullability, null coalescing, null-safe calls, null-safe piping #4188
- [ ] Bash Braces Expansion #2317
- [ ] Status of equivalents of BASH history expansion #5011
- [ ] implementation special variables and background jobs? #4564
- [ ] Pasting multi-line command (with backslash) doesn't work #4044
- [x] source .env (/etc/os-release)


- config
    - [x] struct
    - [x] reload
        - keybinding
- sys
    - [x] toggle-proxy
    - [x] timeit (benchmark)
    - [x] datetime convert / format
- prompt
    - [x] nu
        - [x] panache-git
        - [x] k8s
    - [x] startship
        - [x] git
        - [x] k8s
        - [x] ~~right prompt~~
        - [x] ~~indicator~~
    - [ ] time spent
        - [ ] global state
- alias
    - [ ] utils
        - [ ] a: alias
        - [x] e: nvim
        - [x] t: tmux
        - [ ] alias sget='wget -m -k -E -p -np -e robots=off'
        - [x] toggle-proxy
        - slam
        - wg
        - [x] if (( $+commands[ss] )); then
              alias ns='ss -tulwnp'
          else
              alias ns="netstat -plnetu"
          fi
        - china_mirrors
    - [ ] docker
        - [x] docker run
            - [x] docker dev helper
        - [x] list to table
        - [x] dcp
            - [ ] complete: container id with path
        - [-] volume
    - [ ] k8s
        - [x] list to table
        - [x] kubectx kubens
        - [ ] kcp
            - [ ] complete: container id with path
        - [x] ktp ktn
        - [x] ~~kgp with images~~ (kdp)
    - [x] ssh
- completions
    - [x] podman
    - [x] k8s
    - [x] ssh
- git
    - [x] glg
- edit
    - [x] ~~`enter` for `ls`~~
    - [x] ~~`tab` in empty for cd: direct path and then `enter`~~
    - [ ] `ctrl+q`
    - [x] ~~Brace Expansion {,a,b,c}~~ (move)
    - [x] heredoc (multilines string)
- path
    - [x] zoxide
        - [x] named dir
            - auto enter at dir
        - [x] history
            - -
    - [x] popd
        - enter/shells/g #/n/p
- history
    - [ ] per dir
- alternatives
    - [x] yq, jq, rq ...
        - [x] get
        - [x] update
        - [x] insert
        - [x] delete
    - [x] fd (recursive)
        - ls **/*
    - [x] sd
        - 'my_library.rb' | str replace '(.+).rb' '$1.nu'
    - [=] rg
        - [x]find
    - [=] just
        - [x] overlays
        - [x] Parameterizing Scripts
        - [x] hooks
            - [x] enter/leave dir
                - env_change.PWD
            - [x] pre_prompt + cache
    - [x] watchexec
        - watch . { |op, path, new_path| $"($op) ($path) ($new_path)"}
    - [=] curl
        - fetch, post
    - [=] btm
    - [=] dog
    - [=] dust
    - [=] xh
- [x] login shell

### size
    - zsh       4.8M
    - yq        7.0M
    - rq        3.9M
    - watchexec 5.5M
    - sd        1.8M
    - jq        0.4M
