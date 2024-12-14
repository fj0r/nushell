export def --env init [name] {
    $env.SYNC_CACHE = [$nu.data-dir 'sync-cache' $name] | path join
    if not ($env.SYNC_CACHE | path exists) {
        mkdir ([$env.SYNC_CACHE git] | path join)
    }
    {
        sources_map: {
            db: `path-to-sqlite`
            type: sqlite
            tables: {
                history: {
                    dir: history
                }
                scratch: {
                    dir: scratch
                }
            }
        }
        last_commit: '123abc'
    } | to yaml | save -f ([$env.SYNC_CACHE manifest.yaml] | path join)
}
