module webhook {
    export def mattermost [msg: string] {
        let url = (cat $"($env.HOME)/.config/webhook/mattermost" | str trim)
       curl -X POST $url -H 'content-type: application/json' -d ({text: $msg} | to json -r)
    }
}

use webhook *
