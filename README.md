# scripts
Script files for specific OS tasks just for convenience.


## Windows setup

Edit the environment variables

| Variable | Value |
| --- | --- |
| SCRIPTS_HOME | *Scripts repo location* |
| ENV_VARS_FILE | *Variables file location* \* |
| Path | %Path%;%SCRIPTS_HOME%;%SCRIPTS_HOME%\.libs;%SCRIPTS_HOME%\<dir_1>;%SCRIPTS_HOME%\<dir_n>; \** |

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
