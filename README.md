# scripts
Script files for specific OS tasks just for convenience.


## Windows setup

Edit the environment variables

| Variable | Value |
| --- | --- |
| SCRIPTS_HOME | *Scripts repo location* |
| ENV_VARS_FILE | *Variables file location* \* |
| Path | %Path%;%SCRIPTS_HOME%;%SCRIPTS_HOME%\libs;%SCRIPTS_HOME%\<dir_1>;%SCRIPTS_HOME%\<dir_n>; \** |

> * Example of *env-vars* file:
> ```bat
> set "VARIABLE_1=VALUE1"
> set "VARIABLE_2=VALUE2"
> 
> rem Comment
> ```
> \** Directories: *dev*, *games*, *misc*, *sys*, ...


## Linux setup

Add the required environment variable to *~/.bashrc* file
```sh
vim ~/.bashrc
# vim>
# export ENV_VARS_FILE="<vars_file_location>"

source ~/.bashrc
```

> * Example of *env-vars* file:
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
        },
        {
            "id": "sourceDir",
            "description": "Source location directory",
            "default": "/path",
            "type": "promptString"
        }
    ]
}
```
> Expected environment variables:
> - OLLAMA_SERVER: `http://localhost:11434`
> - OLLAMA_MODELS_DEF_FILE: `/path/.../ollama-models`
> - OPENCODE_CONFIG_FILE: `${userHome}/.config/opencode/opencode.json`
> - SNAPSHOTS_SOURCE_DIR: `${input:sourceDir}`
> - SNAPSHOTS_TO_KEEP: `1`
