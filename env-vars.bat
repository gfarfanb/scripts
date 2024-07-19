@echo OFF

set PWD=%cd%

if "%ENV_VARS_FILE%"=="" (
    echo "Specify environment variables file by defining the environment variable 'ENV_VARS_FILE=...'"
    goto :eof
)

set __timestamp=%date%-%time%
set __timestamp=%__timestamp:/=-%
set __timestamp=%__timestamp::=_%
set __timestamp=%__timestamp: =_%
set __timestamp=%__timestamp:.=_%

set __env_vars_bat="%TEMP%\env-vars-%__timestamp%.bat"

more "%ENV_VARS_FILE%" > "%__env_vars_bat%"

call "%__env_vars_bat%"
del "%__env_vars_bat%"
