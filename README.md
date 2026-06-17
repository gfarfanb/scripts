
# scripts
Script files for specific OS tasks just for convenience.


## Windows setup

Edit the environment variables

| Variable | Value |
| --- | --- |
| ENV_VARS_FILE | *Environment variables file location* |
| SCRIPTS_HOME | *Scripts repo location* |
| PYLIBSPATH | `%SCRIPTS_HOME%\.py` |

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
echo 'export PYLIBSPATH="$SCRIPTS_HOME/.py"' >> ~/.bashrc
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


## OpenCode configuration

### Graphify

[Graphify](https://github.com/safishamsi/graphify) installation
```sh
uv tool install graphifyy

graphify --version

# Add-ons
uv tool install "graphifyy[pdf,office,google,mcp,svg,ollama,sql,postgres]"
```
> [uv](https://docs.astral.sh/uv/getting-started/installation/) is required here

Required environment variables
| Variable | Value |
| --- | --- |
| OPENAI_BASE_URL | <openai_compatible_base_url> |
| OPENAI_API_KEY | <openai_api_key> |

Project initialization
```sh
cd <project_home>

graphify opencode install --project
```

Graph bulding
```sh
# Initialization
graphify . --model <model>

# Update
graphify update . --model <model>
```

Skill update
```sh
graphify opencode install
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
