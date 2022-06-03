let dir-overlay = { |before, after|
    let o = $"($after)/overlay.nu"
    if ($o | path exists) {
        #TODO: unimplement
        #overlay add overlay.nu
    }
}
