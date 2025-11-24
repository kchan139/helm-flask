CREATE TABLE IF NOT EXISTS polls (
    id SERIAL PRIMARY KEY,
    workspace_id VARCHAR(100) NOT NULL DEFAULT 'default',
    title VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_workspace ON polls(workspace_id);

CREATE TABLE IF NOT EXISTS options (
    id SERIAL PRIMARY KEY,
    poll_id INT REFERENCES polls(id) ON DELETE CASCADE,
    text VARCHAR(255) NOT NULL,
    votes INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS votes (
    id SERIAL PRIMARY KEY,
    poll_id INT REFERENCES polls(id) ON DELETE CASCADE,
    voter_ip VARCHAR(45) NOT NULL,
    voted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(poll_id, voter_ip)
);
