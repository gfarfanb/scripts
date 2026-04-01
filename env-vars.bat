@echo OFF

rem __usage_lib_page:
rem Defines common environment variables and
rem imports environment variables from from $ENV_VARS_FILE file
rem
rem Usage in script:
rem   @echo OFF
rem   set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
rem   cd %BASEDIR%
rem
rem   call .\env-vars rem Relative call
rem
rem   call .\.win\require-var <ENVIRONMENT_VARIABLE>

set "TEMP_DIR=%TEMP%"
set "STEMP_DIR=%TEMP%"
set "USER_HOME=%USERPROFILE%"

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
