
-- definition

CREATE TABLE url_mappings (
        host TEXT PRIMARY KEY,
        source TEXT NOT NULL,
        cookies_host TEXT NOT NULL
    );

CREATE TABLE downloads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
       	url TEXT NOT NULL,
       	host TEXT NOT NULL,
       	tries INTEGER NOT NULL DEFAULT 1,
       	format TEXT NOT NULL CHECK (format IN ('AUDIO', 'VIDEO')),
        details TEXT,
       	output_file TEXT,
       	last_dl_status TEXT NOT NULL CHECK (last_dl_status IN ('SUCCESS', 'FAILED')),
       	last_dl_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       	FOREIGN KEY (host) REFERENCES url_mappings(host)
    );

CREATE INDEX idx_downloads_url ON downloads(url);
CREATE INDEX idx_downloads_source ON downloads(host);


-- data

INSERT INTO url_mappings VALUES
    ('youtu.be', 'YouTube', '.youtube.com'),
    ('youtube.com', 'YouTube', '.youtube.com'),
    ('www.youtube.com', 'YouTube', '.youtube.com'),
    ('music.youtube.com', 'YouTube', '.youtube.com');
