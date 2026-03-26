export-env {
    use ../scripts/llm/integration/ollama.nu *
    use ../scripts/llm/call.nu *
    use ../scripts/llm/function.nu *
    use ../scripts/llm/data/tools/os.nu
    use ../scripts/llm/data/tools/web.nu
    use ../scripts/llm/data/tools/git.nu
    use ../scripts/llm/data/tools/programming.nu
    use ../scripts/llm/data/tools/clipboard.nu
    $env.AI_CONFIG = {
        finish_reason: {
            enable: true
            color: xterm_grey30
        }
        reasoning_content: {
            color: grey
            delimiter: $'(char newline)------(char newline)'
        }
        tool_calls: grey
        template_calls: xterm_fuchsia
        message_limit: 20
        permitted-write: ~/Downloads
    }
    use ../scripts/llm/data/assistant/supervisor
}

export use ../scripts/llm/call.nu *
export use ../scripts/llm/shortcut.nu *

export use ../scripts/llm/integration/ollama.nu *
export use ../scripts/llm/integration/local.nu *
export use ../scripts/llm/integration/audio.nu *
