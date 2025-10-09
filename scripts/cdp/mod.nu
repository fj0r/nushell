export-env {
    $env.CDP_PORT = 9222
    $env.CDP_COUNT = 0
    $env.CDP_URL = ''
}

export def 'cdp up' [
    url:string = 'about:blank'
] {
    mut args = [
        --no-first-run --no-default-browser-check
        --user-data-dir=/tmp/chrome-cdp
        $"--remote-debugging-port=($env.CDP_PORT)"
        --disable-backgrounding-occluded-window
        --disable-renderer-backgrounding  $url
    ]
    chromium ...$args
}

export def --env 'cdp url' [
] {
    if ($env.CDP_URL | is-empty) {
        $env.CDP_URL = http get $"http://localhost:($env.CDP_PORT)/json/list"
        | get webSocketDebuggerUrl.0
    }
}

export def --env 'cdp send' [
    data
] {
    cdp url
    $env.CDP_COUNT += 1
    $data
    | upsert id $env.CDP_COUNT
    | to json -r
    | websocat -1 -t $env.CDP_URL
}

export def 'cdp enable' [] {
    cdp send {method: 'Page.enable', params: {}}
    cdp send {method: 'Runtime.enable', params: {}}
    cdp send {method: 'Network.enable', params: {}}
    cdp send {method: 'DOM.enable', params: {}}
}

export def --env 'cdp goto' [
    url
] {
    cdp send {method: 'Page.navigate', params: {url: $url}}
}

export def --env 'cdp reload' [] {
    cdp send {method: 'Page.reload', params: {ignoreCache: true}}
}

export def --env 'cdp wait' [] {
    cdp send {method: 'Page.loadEventFired', params: {}}
}

export def --env 'cdp eval' [exp] {
    cdp send {method: 'Runtime.evaluate	', params: {expression: $exp, returnByValue: true}}
}

export def --env 'cdp get_documnet' [] {
    cdp send {method: 'DOM.getDocument', params: {}}
}

export def --env 'cdp query' [id, selector] {
    cdp send {method: 'DOM.querySelector', params: {nodeId: $id, selector: $selector }}
}
