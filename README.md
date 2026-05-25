
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
