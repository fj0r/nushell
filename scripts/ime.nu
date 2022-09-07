def IM_MODULE [] { 'fcitx5' } 
export env GTK_IM_MODULE { IM_MODULE }
export env QT_IM_MODULE { IM_MODULE }
export env XMODIFIERS { $"@im=(IM_MODULE)" }
