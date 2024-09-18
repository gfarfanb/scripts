@echo OFF

if "%ENV_VARS_FILE%"=="" (
    echo Specify environment variables file by defining the environment variable 'ENV_VARS_FILE=...'
    goto :eof
)

if not exist "%ENV_VARS_FILE%" (
    echo Environment variables file not found at: '%ENV_VARS_FILE%'
    goto :eof
)

setlocal

set __env_vars_tag=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%-%RANDOM%_%RANDOM%
set __env_vars_bat="%TEMP%\env-vars-%__env_vars_tag%.bat"

more "%ENV_VARS_FILE%" > "%__env_vars_bat%"

endlocal & call "%__env_vars_bat%" & del "%__env_vars_bat%"
