export def ai_stat [] {
    {|bg|
        let info = $env.NU_POWER_CONFIG.ai.info
        if ($env.AI_SESSION? | is-not-empty) {
            let i = if ($info | is-not-empty) {
                ai-session | get $info
            } else {
                ''
            }
            [$bg $'($i)✨($env.AI_SESSION)']
        } else {
            ['#504945' null]
        }
    }
}

export-env {
    power register ai (ai_stat) {
        info: provider
    }
}
