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
    pull INTEGER NOT NULL DEFAULT 0,
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
WITH _o_hub AS (
    SELECT id
        FROM hubs
        WHERE name IN ('Ollama Local', 'Ollama Cloud')
)
INSERT INTO ollama_templates (hub_id, template)
    SELECT id, '{model}[:{parameters}]' FROM _o_hub;


-- Ollama Templates for Hugging Face models
WITH _h_f_hub AS (
    SELECT id
        FROM hubs
        WHERE name IN ('Hugging Face')
)
INSERT INTO ollama_templates (hub_id, template)
    SELECT id, 'hf.co/{organization}/{model}[:{quantization}]' FROM _h_f_hub;


-- Ollama Models
WITH _o_template AS (
    SELECT ot.id, h.name
        FROM ollama_templates ot
            JOIN hubs h ON ot.hub_id = h.id
)
INSERT INTO ollama_models(name, template_id, model, parameters, organization, quantization, basename, pull) VALUES
    ('Nomic', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'nomic-embed-text', 'v1.5', null, null, null, 1),
    ('Mistral', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'mistral', '7b-instruct-v0.3-q4_K_M', null, null, 'Mistral-7B-Instruct-v0.3', 1),
    ('Phi-3.5', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'phi3.5', '3.8b-mini-instruct-q4_K_M', null, null, null, 1),
    ('Llama 3.2', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'llama3.2', '3b', null, null, null, 1),
    ('Qwen3-VL', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'qwen3-vl', '8b', null, null, null, 1),
    ('Qwen3-VL', (SELECT id FROM _o_template WHERE name = 'Hugging Face'),
        'Qwen3-VL-8B-Thinking-GGUF', null, 'Qwen', 'Q4_K_M', null, 0),
    ('Rnj-1', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'rnj-1', '8b', null, null, null, 1),
    ('Granite-4.0', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'granite4', '7b-a1b-h', null, null, 'Granite-4.0-H-Tiny', 1),
    ('Gemma 4', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'gemma4', 'e2b', null, null, null, 1),
    ('Gemma 4', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'gemma4', 'e4b', null, null, null, 1),
    ('DeepSeek-R1', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'deepseek-r1', '8b', null, null, 'DeepSeek-R1-0528-Qwen3-8B', 0),
    ('Llama 3.1', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'llama3.1', '8b-instruct-q4_K_M', null, null, null, 0),
    ('Code Llama', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'codellama', '7b-code-q4_K_M', null, null, null, 0),
    ('Qwen3', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'qwen3', '8b', null, null, null, 0),
    ('Qwen3', (SELECT id FROM _o_template WHERE name = 'Hugging Face'),
        'Qwen3-8B-GGUF', null, 'Qwen', 'Q4_K_M', null, 0),
    ('Granite-Embedding', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'granite-embedding', '278m', null, null, null, 0),
    ('Gemma 3', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'gemma3', '12b', null, null, null, 0),
    ('Cogito-v1-Preview', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'cogito', '8b', null, null, null, 0),
    ('Qwen2.5-Coder', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'qwen2.5-coder', '14b', null, null, null, 0),
    ('Qwen3-Embedding', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'qwen3-embedding', '8b', null, null, null, 0),
    ('EmbeddingGemma', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'embeddinggemma', '300m', null, null, null, 0),
    ('LFM2.5', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'lfm2.5-thinking', '1.2b', null, null, 'LFM2.5-1.2B-Thinking', 0),
    ('TranslateGemma', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'translategemma', '12b', null, null, null, 0),
    ('DeepSeek-OCR', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'deepseek-ocr', '3b', null, null, null, 0),
    ('Gemma-3n', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'gemma3n', 'e4b', null, null, null, 0),
    ('Ministral-3', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'ministral-3', '14b', null, null, null, 0),
    ('BitNet b1.58 2B4T', (SELECT id FROM _o_template WHERE name = 'Hugging Face'),
        'bitnet-b1.58-2B-4T-gguf', null, 'microsoft', null, null, 0),
    ('Granite Docling', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'ministral', '258m', null, null, null, 0),
    ('Qwen3.5', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'qwen3.5', '4b-q4_K_M', null, null, null, 0),
    ('LLaVA', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'llava', '7b-v1.6-mistral-q4_K_M', null, null, null, 0),
    ('GLM-OCR', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'glm-ocr', 'bf16', null, null, null, 0),
    ('LLaVA Phi 3', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'llava-phi3', '3.8b', null, null, null, 0),
    ('Granite-3.1 MoE', (SELECT id FROM _o_template WHERE name = 'Ollama Local'),
        'granite3.1-moe', '3b', null, null, null, 0);
