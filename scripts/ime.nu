def IM_MODULE [] { 'fcitx5' }
export-env {
    let-env GTK_IM_MODULE = IM_MODULE
    let-env QT_IM_MODULE = IM_MODULE
    let-env XMODIFIERS = $"@im=(IM_MODULE)"
}
