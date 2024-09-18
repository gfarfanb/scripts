@echo OFF
set PWD=%cd%

call env-vars.bat
call require-var EXECUTABLE_COMMANDS_LENGTH

for /l %%i in (1,1,%EXECUTABLE_COMMANDS_LENGTH%) do (
    call require-var EXECUTABLE_NAMES[%%i]
    call require-var EXECUTABLE_COMMANDS[%%i]
)

goto main

:usage
echo Launches an executable file.
echo:
echo Usage: %0 [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto back

:main
if /i "%1"=="-h" goto usage

setlocal enableDelayedExpansion

echo Select an executable:
for /l %%i in (1,1,%EXECUTABLE_COMMANDS_LENGTH%) do (
    set "_app_name=!EXECUTABLE_NAMES[%%i]!"

    for /f "delims=" %%j in ("!EXECUTABLE_COMMANDS[%%i]!") do (
        if exist %%j (
            echo %%i^) !_app_name! [%%~nxj]
        ) else (
            echo %%i^) ^(not found^) !_app_name!
        )
    )
)

set /P _app_index="app-index> "

set "_app_path=!EXECUTABLE_COMMANDS[%_app_index%]!"

if "%_app_path%"=="" (
    echo Invalid app index
    echo [Process stopped]
    goto back
)

if exist "%_app_path%" (
    call "%_app_path%"
) else (
    echo '!EXECUTABLE_NAMES[%_app_index%]!' executable not found
    echo [Process stopped]
    goto back
)

echo [Completed]
goto back

endlocal

:back
cd /d %PWD%
