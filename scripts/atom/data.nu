use sqlite.nu *


export def --env init [] {
    init-db ATOM_STATE ([$nu.data-dir 'atom.db'] | path join) {|sqlx, Q|
        for s in [
            "CREATE TABLE IF NOT EXISTS tag (
                id INTEGER PRIMARY KEY,
                parent_id INTEGER DEFAULT -1,
                name TEXT NOT NULL,
                alias TEXT NOT NULL DEFAULT '',
                hidden BOOLEAN DEFAULT 0,
                UNIQUE(parent_id, name)
            );"
        ] {
            do $sqlx $s
        }
        seed
    }
}
