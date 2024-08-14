# scripts
Script files for specific OS tasks just for convenience.


## Windows setup

Edit the environment variables

| Variable | Value |
| --- | --- |
| SCRIPTS_HOME | *Scripts repo location* |
| ENV_VARS_FILE | *Variables file location* \* |
| Path | %Path%;%SCRIPTS_HOME%;%SCRIPTS_HOME%\games;%SCRIPTS_HOME%\pkb \** |

> * File extension is not needed, example file:
> ```bat
> set "VARIABLE_1=VALUE1"
> set "VARIABLE_2=VALUE2"
> 
> rem Comment
> ```
> \** *games* and *pkb* sub-directories are optional


## Debian-based setup

Add the required environment variable to **.bashrc** file
```sh
echo 'export ENV_VARS_FILE=<vars-file-location>' | sudo tee -a ~/.bashrc >/dev/null
```

> * Example file:
> ```bash
> VARIABLE_1="VALUE1"
> VARIABLE_2=VALUE2
> 
> # Comment
> ```
