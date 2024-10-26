def surreal-conn [conn loc --protocol(-p): string='http'] {
    [
        -u $"($conn.username):($conn.password)"
        -H $"surreal-ns: ($conn.ns)"
        -H $"surreal-db: ($conn.db)"
        -H "Accept: application/json"
        $"($protocol)://($conn.host):($conn.port)/($loc)"
    ]
}

export-env {
    if 'SURREALDB' not-in $env {
        $env.SURREALDB = {
            host: localhost
            port: 9900
            db: foo
            ns: foo
            username: foo
            password: foo
        }
    }
}


export def query [] {
    $in
    |curl -sSL -X POST ...(surreal-conn $env.SURREALDB 'sql') --data-binary @-
    | from json
}