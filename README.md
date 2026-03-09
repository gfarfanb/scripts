
# scripts
Script files for specific OS tasks just for convenience.


## Windows setup

Edit the environment variables

| Variable | Value |
| --- | --- |
| SCRIPTS_HOME | *Scripts repo location* |
| ENV_VARS_FILE | *Environment variables file location* |
| PROPSPATH | *props.bat script directory* |
| Path | %Path%;%SCRIPTS_HOME%;%SCRIPTS_HOME%\win;<other_scripts_dirs>; |

Example of *env-vars* file:
```bat
set "VARIABLE_1=VALUE1"
set "VARIABLE_2=VALUE2"

rem Comment
```


## Linux setup

Add the required environment variable to *~/.bashrc* file
```sh
vim ~/.bashrc
# vim>
# export ENV_VARS_FILE="<environment_variables_file_location>"
# export PROPSPATH="<props_script_directory>"

source ~/.bashrc
```

Example of *env-vars* file:
```bash
VARIABLE_1="VALUE1"
VARIABLE_2=VALUE2

# Comment
```


## VS Code configuration

**\<PROJECT_DIR>/.vscode/launch.json**
```json title="launch.json"
{
    // ...
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python Debugger: Python File",
            "type": "debugpy",
            "request": "launch",
            "program": "${file}",
            "env": {
                "LOGGING_LEVEL": "${input:loggingLevel}",
                "<env_var>": "<value>"
            }
        }
    ],
    "inputs": [
        {
            "id": "loggingLevel",
            "description": "Logging level",
            "type": "pickString",
            "options": [
                "CRITICAL", "FATAL", "ERROR", "WARNING", "WARNING", "INFO", "DEBUG", "NOTSET"
            ],
            "default": "INFO"
        }
    ]
}
```


## Ollama Models definition

```json
{
    "<model_identifier>": {
        "name": "<model_display_name>",
        "readonly": true,
        "hub": "ollama|huggingface",
        "ollama": {
            "model": "<model>",
            "parameters": "<parameters>",
            "opencode": true,
            "embeddings": true
        },
        "huggingface": {
            "organization": "<organization_name>",
            "model": "<model>",
            "quantization": "<quantization>",
            "opencode": true,
            "embeddings": true
        }
    }
}
```

| Field | Default Value |
| --- | --- |
| **readonly** | `false` |
| **ollama.opencode** | `false` |
| **huggingface.opencode** | `false` |

> \* `.<SCRIPTS_LLM_HOME>/sync-models`
