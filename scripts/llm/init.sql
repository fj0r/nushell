CREATE TABLE IF NOT EXISTS provider (
    name TEXT PRIMARY KEY,
    baseurl TEXT NOT NULL,
    api_key TEXT DEFAULT '',
    model TEXT DEFAULT 'qwen2:1.5b',
    temperature REAL DEFAULT 0.5,
    temp_min REAL DEFAULT 0,
    temp_max REAL NOT NULL,
    org_id TEXT DEFAULT '',
    project_id TEXT DEFAULT ''
);

CREATE TABLE IF NOT EXISTS sessions (
    id TEXT,
    provider TEXT NOT NULL,
    model TEXT NOT NULL,
    temperature REAL NOT NULL,
    created TEXT
);


CREATE TABLE IF NOT EXISTS prompt (
    name TEXT PRIMARY KEY,
    system TEXT,
    template TEXT,
    placeholder TEXT,
    description TEXT
);


CREATE TABLE IF NOT EXISTS messages (
    session_id TEXT,
    model TEXT,
    role TEXT,
    message TEXT,
    token INTEGER,
    created TEXT
);

INSERT INTO provider (name, baseurl, temp_max) VALUES ('ollama', 'http://localhost:11434/v1', 1);
