
# scripts
Script files for specific OS tasks just for convenience.


## Windows setup

Edit the environment variables

| Variable | Value |
| --- | --- |
| ENV_VARS_FILE | *Environment variables file location* |
| SCRIPTS_HOME | *Scripts repo location* |
| PROPSPATH | *scripts/ location* |
| PYLIBSPATH | *scripts/.py/ location* |

> Example of *env-vars* file:
> ```bat
> set "VARIABLE_1=VALUE1"
> set "VARIABLE_2=VALUE2"
> 
> rem Comment
> ```


## Linux setup

Add the required environment variable to *~/.bashrc* file
```sh
echo 'export ENV_VARS_FILE="<environment_variables_file_location>"' >> ~/.bashrc
echo 'export SCRIPTS_HOME="<scripts_location>"' >> ~/.bashrc
echo 'export PROPSPATH="<scripts_location>"' >> ~/.bashrc
echo 'export PYLIBSPATH="<scripts_py_libs_directory>"' >> ~/.bashrc
echo 'export WIN_IP=$( ip route show | grep -i default | awk '{ print $3}' )' >> ~/.bashrc

source ~/.bashrc
```

> Example of *env-vars* file:
> ```bash
> VARIABLE_1="VALUE1"
> VARIABLE_2=VALUE2
> 
> # Comment
> ```


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
            "info": {
                "basename": "<model_basename>",
                "opencode": true,
                "embeddings": true,
                "image": true,
                "ocr": true
            }

        },
        "huggingface": {
            "organization": "<organization_name>",
            "model": "<model>",
            "quantization": "<quantization>",
            "info": {
                "basename": "<model_basename>",
                "opencode": true,
                "embeddings": true,
                "image": true,
                "ocr": true
            }
        }
    }
}
```

| Field | Default Value |
| --- | --- |
| **readonly** | `false` |
| **\<hub>.info.opencode** | `false` |
| **\<hub>.info.embeddings** | `false` |
| **\<hub>.info.image** | `false` |
| **\<hub>.info.ocr** | `false` |

> \* Windows: `%SCRIPTS_HOME%/llm/sync-ollama` \
> \* Linux: `$SCRIPTS_HOME/llm/sync-ollama`
