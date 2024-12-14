export def --env init [name] {
    $env.SYNC_CACHE = [$nu.data-dir 'sync-cache' $name] | path join
    if not ($env.SYNC_CACHE | path exists) {
        mkdir ([$env.SYNC_CACHE git] | path join)
    }

}
