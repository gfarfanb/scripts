
-- SQLite Database Schema

CREATE TABLE hubs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    base_url TEXT NOT NULL,
    api_key TEXT,
    deleted INTEGER NOT NULL DEFAULT 0
);


CREATE TABLE agents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    url TEXT NOT NULL,
    deleted INTEGER NOT NULL DEFAULT 0
);


CREATE TABLE model_capabilities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    deleted INTEGER NOT NULL DEFAULT 0
);


CREATE TABLE ollama_templates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    hub_id INTEGER NOT NULL,
    template TEXT NOT NULL,
    deleted INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (hub_id) REFERENCES hubs(id)
);

CREATE INDEX idx_ollama_templates_template ON ollama_templates(template);


CREATE TABLE ollama_models (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    template_id INTEGER NOT NULL,
    model TEXT NOT NULL,
    parameters TEXT,
    organization TEXT,
    quantization TEXT,
    basename TEXT,
    pull TEXT CHECK( pull IN ('LOCAL', 'CLOUD', 'READONLY') ) NOT NULL DEFAULT 'READONLY',
    deleted INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (template_id) REFERENCES ollama_templates(id)
);

CREATE INDEX idx_ollama_models_name ON ollama_models(name);
CREATE INDEX idx_ollama_models_model ON ollama_models(model);


CREATE TABLE ollama_models_agents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    model_id INTEGER NOT NULL,
    agent_id INTEGER NOT NULL,
    included INTEGER NOT NULL DEFAULT 0,
    deleted INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (model_id) REFERENCES ollama_models(id),
    FOREIGN KEY (agent_id) REFERENCES agents(id)
);


CREATE TABLE ollama_models_capabilities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    model_id INTEGER NOT NULL,
    capability_id INTEGER NOT NULL,
    deleted INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (model_id) REFERENCES ollama_models(id),
    FOREIGN KEY (capability_id) REFERENCES model_capabilities(id)
);
