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


-- Initial data

-- Hubs
INSERT INTO hubs(name, base_url, api_key) VALUES
    ('Ollama Local', 'http://localhost:11434/v1', 'ollama'),
    ('Ollama Cloud', 'https://ollama.com/v1', 'OLLAMA_API_KEY'),
    ('Hugging Face', 'https://router.huggingface.co/v1', 'HF_TOKEN'),
    ('OpenRouter', 'https://openrouter.ai/api/v1', 'OPENROUTER_API_KEY');


-- Agents
INSERT INTO agents(name, url) VALUES
    ('OpenCode', 'https://opencode.ai/'),
    ('Pi', 'https://pi.dev/');


-- Model Capabilities
INSERT INTO model_capabilities(name) VALUES
    ('embeddings'),
    ('image'),
    ('ocr');


-- Ollama Templates for Ollama Local/Cloud models
INSERT INTO ollama_templates (name, hub_id, template) VALUES
    ('Ollama Pull Cloud', (SELECT id FROM hubs WHERE name = 'Ollama Cloud'), '{model}:{parameters}'),
    ('Ollama Pull', (SELECT id FROM hubs WHERE name = 'Ollama Local'), '{model}:{parameters}'),
    ('Ollama Pull+Hugging Face', (SELECT id FROM hubs WHERE name = 'Ollama Local'), 'hf.co/{organization}/{model}:{quantization}');


-- Ollama Models
WITH _o_template AS (
    SELECT ot.id, ot.name
        FROM ollama_templates ot
            JOIN hubs h ON ot.hub_id = h.id
)
INSERT INTO ollama_models(name, template_id, model, parameters, organization, quantization, basename, pull) VALUES
    ('Nomic', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'nomic-embed-text', 'v1.5', null, null, null, 'LOCAL'),
    ('Mistral', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'mistral', '7b-instruct-v0.3-q4_K_M', null, null, 'Mistral-7B-Instruct-v0.3', 'LOCAL'),
    ('Phi-3.5', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'phi3.5', '3.8b-mini-instruct-q4_K_M', null, null, null, 'LOCAL'),
    ('Llama 3.2', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'llama3.2', '3b', null, null, null, 'LOCAL'),
    ('Qwen3-VL', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'qwen3-vl', '8b', null, null, null, 'LOCAL'),
    ('Qwen3-VL', (SELECT id FROM _o_template WHERE name = 'Ollama Pull+Hugging Face'),
        'Qwen3-VL-8B-Thinking-GGUF', null, 'Qwen', 'Q4_K_M', null, 'READONLY'),
    ('Rnj-1', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'rnj-1', '8b', null, null, null, 'LOCAL'),
    ('Granite-4.0', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'granite4', '7b-a1b-h', null, null, 'Granite-4.0-H-Tiny', 'LOCAL'),
    ('Gemma 4', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'gemma4', 'e2b', null, null, null, 'LOCAL'),
    ('Gemma 4', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'gemma4', 'e4b', null, null, null, 'LOCAL'),
    ('DeepSeek-R1', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'deepseek-r1', '8b', null, null, 'DeepSeek-R1-0528-Qwen3-8B', 'READONLY'),
    ('Llama 3.1', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'llama3.1', '8b-instruct-q4_K_M', null, null, null, 'READONLY'),
    ('Code Llama', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'codellama', '7b-code-q4_K_M', null, null, null, 'READONLY'),
    ('Qwen3', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'qwen3', '8b', null, null, null, 'READONLY'),
    ('Qwen3', (SELECT id FROM _o_template WHERE name = 'Ollama Pull+Hugging Face'),
        'Qwen3-8B-GGUF', null, 'Qwen', 'Q4_K_M', null, 'READONLY'),
    ('Granite-Embedding', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'granite-embedding', '278m', null, null, null, 'READONLY'),
    ('Gemma 3', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'gemma3', '12b', null, null, null, 'READONLY'),
    ('Cogito-v1-Preview', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'cogito', '8b', null, null, null, 'READONLY'),
    ('Qwen2.5-Coder', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'qwen2.5-coder', '14b', null, null, null, 'READONLY'),
    ('Qwen3-Embedding', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'qwen3-embedding', '8b', null, null, null, 'READONLY'),
    ('EmbeddingGemma', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'embeddinggemma', '300m', null, null, null, 'READONLY'),
    ('LFM2.5', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'lfm2.5-thinking', '1.2b', null, null, 'LFM2.5-1.2B-Thinking', 'READONLY'),
    ('TranslateGemma', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'translategemma', '12b', null, null, null, 'READONLY'),
    ('DeepSeek-OCR', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'deepseek-ocr', '3b', null, null, null, 'READONLY'),
    ('Gemma-3n', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'gemma3n', 'e4b', null, null, null, 'READONLY'),
    ('Ministral-3', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'ministral-3', '14b', null, null, null, 'READONLY'),
    ('BitNet b1.58 2B4T', (SELECT id FROM _o_template WHERE name = 'Ollama Pull+Hugging Face'),
        'bitnet-b1.58-2B-4T-gguf', null, 'microsoft', null, null, 'READONLY'),
    ('Granite Docling', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'ministral', '258m', null, null, null, 'READONLY'),
    ('Qwen3.5', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'qwen3.5', '4b-q4_K_M', null, null, null, 'READONLY'),
    ('LLaVA', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'llava', '7b-v1.6-mistral-q4_K_M', null, null, null, 'READONLY'),
    ('GLM-OCR', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'glm-ocr', 'bf16', null, null, null, 'READONLY'),
    ('LLaVA Phi 3', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'llava-phi3', '3.8b', null, null, null, 'READONLY'),
    ('Granite-3.1 MoE', (SELECT id FROM _o_template WHERE name = 'Ollama Pull'),
        'granite3.1-moe', '3b', null, null, null, 'READONLY'),
    ('MiniMax M2.7', (SELECT id FROM _o_template WHERE name = 'Ollama Pull Cloud'),
        'minimax-m2.7', 'cloud', null, null, null, 'READONLY');


-- Ollama Models for Pi
WITH _agent AS (
    SELECT a.id
        FROM agents a
        WHERE name = 'Pi'
)
INSERT INTO ollama_models_agents(model_id, agent_id, included) VALUES
    ((SELECT id FROM ollama_models WHERE model = 'mistral'), (SELECT id FROM _agent), 1),
    ((SELECT id FROM ollama_models WHERE model = 'phi3.5'), (SELECT id FROM _agent), 1),
    ((SELECT id FROM ollama_models WHERE model = 'llama3.2'), (SELECT id FROM _agent), 1),
    ((SELECT id FROM ollama_models WHERE model = 'qwen3-vl'), (SELECT id FROM _agent), 1),
    ((SELECT id FROM ollama_models WHERE model = 'Qwen3-VL-8B-Thinking-GGUF'), (SELECT id FROM _agent), 1),
    ((SELECT id FROM ollama_models WHERE model = 'rnj-1'), (SELECT id FROM _agent), 1),
    ((SELECT id FROM ollama_models WHERE model = 'granite4'), (SELECT id FROM _agent), 1),
    ((SELECT id FROM ollama_models WHERE model = 'gemma4' AND parameters = 'e4b'), (SELECT id FROM _agent), 1),
    ((SELECT id FROM ollama_models WHERE model = 'gemma4' AND parameters = 'e2b'), (SELECT id FROM _agent), 1),
    ((SELECT id FROM ollama_models WHERE model = 'minimax-m2.7'), (SELECT id FROM _agent), 0);


-- Ollama Models for OpenCode
WITH _agent AS (
    SELECT a.id
        FROM agents a
        WHERE name = 'OpenCode'
)
INSERT INTO ollama_models_agents(model_id, agent_id, included) VALUES
    ((SELECT id FROM ollama_models WHERE model = 'gemma4' AND parameters = 'e4b'), (SELECT id FROM _agent), 1);
