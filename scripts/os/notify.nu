export def notify-self [msg?] {
    notify-send $env.pwd ($msg | default '')
}
