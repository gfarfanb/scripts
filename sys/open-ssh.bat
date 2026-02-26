@echo OFF
set PWD=%cd%

call env-vars.bat
call require-var OPEN_SSH_HOSTS_FILE
call require-var OPEN_SSH_CLIENT

goto main

:usage
echo Open a SSH connection based on a known hosts
echo:
echo Usage: %0 [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto back

:main
if /i "%~1"=="-h" goto usage

call source-file "%OPEN_SSH_HOSTS_FILE%"

setlocal enableDelayedExpansion

echo Select a knwon host:
for /l %%i in (1,1,%KNOWN_HOST_LENGTH%) do (
    set "_KNOWN_HOST=!KNOWN_HOST[%%i]!"

    if "%%i"=="%KNOWN_HOST_DEFAULT_INDEX%" (
        echo %%i^) ^(default^) !_KNOWN_HOST!
    ) else (
        echo %%i^) !_KNOWN_HOST!
    )
)

set "_KNOWN_HOST_INDEX="
set /P _KNOWN_HOST_INDEX="host-index> "
if "%_KNOWN_HOST_INDEX%"=="" set _KNOWN_HOST_INDEX=%KNOWN_HOST_DEFAULT_INDEX%

set "_KNOWN_HOST=!KNOWN_HOST[%_KNOWN_HOST_INDEX%]!"
set "_KNOWN_USER=!KNOWN_HOST_DEFAULT_USER[%_KNOWN_HOST_INDEX%]!"
set "_REQUIRED_PRIVATE_KEY=!KNOWN_HOST_PRIVATE_KEY[%_KNOWN_HOST_INDEX%]!"
set "_PRIVATE_KEY_OPT="

if "%OPEN_SSH_CLIENT%"=="putty" goto clientputty
if "%OPEN_SSH_CLIENT%"=="ssh" goto clientssh
goto invalidssh


:clientputty
if "%_REQUIRED_PRIVATE_KEY%"=="1" (
    call require-var OPEN_SSH_PRIVATE_KEY_LOCATION

    set "_PRIVATE_KEY_OPT= -i ^"%OPEN_SSH_PRIVATE_KEY_LOCATION%^""
)

if "%_KNOWN_USER%"=="" (
    set "_SSH_CMD=putty %_KNOWN_HOST% -P 22 %_PRIVATE_KEY_OPT%"
) else (
    set "_SSH_CMD=putty %_KNOWN_USER%@%_KNOWN_HOST% -P 22 %_PRIVATE_KEY_OPT%"
)
goto executessh


:clientssh
if "%_REQUIRED_PRIVATE_KEY%"=="1" (
    call require-var OPEN_SSH_PRIVATE_KEY_LOCATION

    set "_PRIVATE_KEY_OPT= -i ^"%OPEN_SSH_PRIVATE_KEY_LOCATION%^""
)

if "%_KNOWN_USER%"=="" (
    set "_SSH_CMD=ssh %_KNOWN_HOST% %_PRIVATE_KEY_OPT%"
) else (
    set "_SSH_CMD=ssh %_KNOWN_USER%@%_KNOWN_HOST% %_PRIVATE_KEY_OPT%"
)
goto executessh


:executessh
echo:
echo %_SSH_CMD%
start /b %_SSH_CMD%
goto completed

endlocal


:invalidssh
echo Invalid SSH client
echo [Process invalid]: %0
goto back


:completed
echo [Completed]: %0
goto back


:back
cd /d %PWD%
