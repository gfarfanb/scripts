
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
