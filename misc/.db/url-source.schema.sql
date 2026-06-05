

CREATE TABLE host_mappings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        host TEXT NOT NULL,
        source TEXT NOT NULL,
        cookies_host TEXT NOT NULL,
        deleted INTEGER NOT NULL DEFAULT 0
    );

CREATE INDEX idx_host_mappings_host ON host_mappings(host);


CREATE TABLE downloads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
       	url TEXT NOT NULL,
       	host_id TEXT NOT NULL,
       	tries INTEGER NOT NULL DEFAULT 1,
       	format TEXT NOT NULL CHECK (format IN ('AUDIO', 'VIDEO')),
        details TEXT,
       	output_file TEXT,
       	last_dl_status TEXT NOT NULL CHECK (last_dl_status IN ('SUCCESS', 'FAILED')),
       	last_dl_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        deleted INTEGER NOT NULL DEFAULT 0,
       	FOREIGN KEY (host_id) REFERENCES host_mappings(id)
    );

CREATE INDEX idx_downloads_url ON downloads(url);
