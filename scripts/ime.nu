def IM_MODULE [] { 'fcitx5' }
export-env {
    $env.GTK_IM_MODULE = IM_MODULE
    $env.QT_IM_MODULE = IM_MODULE
    $env.XMODIFIERS = $"@im=(IM_MODULE)"
}
