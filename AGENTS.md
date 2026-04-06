# AGENTS.md

This is a scripts collection repository for OS-specific utilities. It contains shell scripts (Bash), batch files (Windows), and supporting Python utilities.

## Repository Structure

- **Root scripts**: `props`, `props.bat`, `env-vars`, `env-vars.bat` - environment and configuration management utilities
- **`dev/`**: Development service startup scripts (Kafka, PostgreSQL, Redis, SonarQube, JDK setup, etc.)
- **`llm/`**: LLM and OpenCode-related scripts (`start-opencode`, `sync-ollama` for Ollama model management)
- **`sys/`**: System utilities (`sync-repos` for git repository management, `save-snapshot` for backups, `dirs` for navigation)
- **`games/`**: Gaming tools and launcher scripts
- **`misc/`**: Miscellaneous utilities
- **`.win/`**: Windows-specific utility scripts (batch helpers like `require-var.bat`, `eval.bat`, `sha256sum.bat`)
- **`.py/`**: Shared Python libraries
  - `env_vars.py`: Environment variable loader (reads from `$ENV_VARS_FILE`)
  - `ollama_models.py`: Ollama model sync utility
  - `backup_repos.py`: Repository cloning/pulling utility

## Environment Variables

Scripts require these to be set (Windows: `env-vars.bat`; Linux: sourced from `~/.bashrc`):

- `ENV_VARS_FILE`: Path to external environment variables configuration file
- `SCRIPTS_HOME`: Scripts repository root directory
- `PROPSPATH`: Scripts root (typically same as `SCRIPTS_HOME`)
- `PYLIBSPATH`: Path to `.py/` directory (for Python imports)
- `WORKSPACE_HOME`: Workspace location (used by repo sync)
- `REPOS_HOME`: Repository root directory (used by `sync-repos`)
- `REPOS_DEF_FILE`: JSON file defining repositories to sync
- `OPENCODE_SERVER_PORT`: Port for OpenCode server (used by `start-opencode`)
- `OLLAMA_SERVER`: Ollama instance URL
- `OLLAMA_MODELS_DEF_FILE`: JSON file defining Ollama models
- `OPENCODE_CONFIG_FILE`: OpenCode configuration file path

## Key Patterns

### Script Entry Points (Windows)
All `.bat` scripts follow a standard pattern:
1. Call `.\env-vars` (or `..\env-vars` from subdirectories) to load configuration
2. Validate required variables with `.\.win\require-var VAR_NAME`
3. Execute main logic or delegate to Python scripts
4. Use `:completed`, `:back`, `:stopped` label pattern for cleanup

Example:
```bat
call ..\env-vars
call ..\.win\require-var OPENCODE_SERVER_PORT
opencode serve --port %OPENCODE_SERVER_PORT% --hostname 0.0.0.0
goto :completed
```

### Script Entry Points (Bash)
All shell scripts source `./env-vars` or `../env-vars` and use helper functions:
- `_require_var VAR_NAME`: Validate variable exists
- `_completed`: Exit with cleanup message
- `_stopped`: Exit with error message
- `_kill_process`: Terminate process by name

### Python Dependencies
- `env_vars.py`: Provides `env_value()` to read from `$ENV_VARS_FILE` or environment, with fallback to `props` command
- Scripts must append `environ['PYLIBSPATH']` to `sys.path` before importing shared modules

### Configuration Files (JSON)
- **`$REPOS_DEF_FILE`**: Repository definitions with `location`, `name`, `branch`, `pullRequired`, `type` (github/gitlab), `username`, `repo`
- **`$OLLAMA_MODELS_DEF_FILE`**: Model definitions with `name`, `readonly`, `hub` (ollama/huggingface), provider-specific config, and `info` flags (opencode, embeddings, image, ocr)
- **`$OPENCODE_CONFIG_FILE`**: OpenCode server configuration

## Testing & Validation

- Windows batch scripts have `-h` help option showing usage
- Bash scripts also have `-h` help option
- Use `props` (Linux) or `props.bat` (Windows) to list/display environment variables
- Python scripts use `logging` module; set `LOGGING_LEVEL` environment variable (default: INFO)

## Common Tasks

**Sync repositories**: `sys/sync-repos [-b] [-s]` - clone missing or pull existing repos
**Sync Ollama models**: `llm/sync-ollama` - pull/sync LLM models from definition file
**Start OpenCode server**: `llm/start-opencode` - launch on configured port
**Backup repositories**: `sys/sync-repos -b` - create ZIP backups

## Development Notes

- Cross-platform support: Scripts have both `.bat` (Windows) and shell (Linux) versions
- No test automation; scripts are primarily for manual OS task execution
- `.archived/` directory contains deprecated scripts
- Python 2/3 compatibility handled with `$(command -v python3 || command -v python)`
