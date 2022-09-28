def IM_MODULE [] { 'fcitx5' }
export-env {
    let GTK_IM_MODULE = IM_MODULE
    let QT_IM_MODULE = IM_MODULE
    let XMODIFIERS = $"@im=(IM_MODULE)"
}
