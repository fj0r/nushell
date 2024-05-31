for e in [nuon toml yaml json] {
    if ($".env.($e)" |  path exists) {
        open $".env.($e)" | load-env
    }
}
