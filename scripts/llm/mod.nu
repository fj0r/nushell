export-env {
    use integration/ollama.nu *
    use call.nu *
    use function.nu *
    use data/tools/os.nu
    use data/tools/web.nu
    use data/tools/git.nu
    use data/tools/programming.nu
    $env.AI_CONFIG = {
        finish_reason: {
            enable: false
            color: xterm_grey30
        }
        tool_calls: grey
        template_calls: xterm_fuchsia
        message_limit: 20
        permitted-write: ~/Downloads
    }
    use data/tools/supervisor.nu
}


export use integration/ollama.nu *
export use integration/local.nu *
export use call.nu *
