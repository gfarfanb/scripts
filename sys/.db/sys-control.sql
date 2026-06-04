-- SQLite Database Schema

CREATE TABLE operating_systems (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    deleted INTEGER NOT NULL DEFAULT 0
);


CREATE TABLE machines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    dir_base TEXT NOT NULL,
    os_id INTEGER NOT NULL,
    parent_id INTEGER,
    deleted INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (os_id) REFERENCES operating_systems(id),
    FOREIGN KEY (parent_id) REFERENCES machines(id)
);


CREATE TABLE repo_hubs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    clone_template TEXT NOT NULL,
    backup_template TEXT NOT NULL,
    deleted INTEGER NOT NULL DEFAULT 0
);


CREATE TABLE repos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    machine_id INTEGER NOT NULL,
    repo_name TEXT NOT NULL,
    branch TEXT NOT NULL,
    hub_id TEXT NOT NULL,
    username TEXT NOT NULL,
    pull_required INTEGER NOT NULL DEFAULT 0,
    pull_dir TEXT NOT NULL,
    backup_required INTEGER NOT NULL DEFAULT 0,
    backup_dir TEXT NOT NULL,
    deleted INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (machine_id) REFERENCES machines(id),
    FOREIGN KEY (hub_id) REFERENCES repo_hubs(id)
);


CREATE TABLE commands (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    machine_id INTEGER NOT NULL,
    cli_name TEXT NOT NULL,
    action_cmd TEXT NOT NULL,
    ordinal INTEGER NOT NULL DEFAULT 0,
    mode TEXT CHECK( mode IN ('EXECUTION', 'READONLY') ) NOT NULL DEFAULT 'READONLY',
    approval INTEGER NOT NULL DEFAULT 0,
    approval_msg TEXT,
    reject_cmd TEXT,
    deleted INTEGER NOT NULL DEFAULT 0,
    UNIQUE (machine_id, cli_name),
    FOREIGN KEY (machine_id) REFERENCES machines(id)
);

CREATE INDEX idx_commands_command ON commands(action_cmd);
CREATE INDEX idx_commands_approval_msg ON commands(approval_msg);
CREATE INDEX idx_commands_reject_cmd ON commands(reject_cmd);
