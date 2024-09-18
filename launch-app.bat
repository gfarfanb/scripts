@echo OFF
set PWD=%cd%

call env-vars.bat
call require-var EXECUTABLE_COMMANDS_LENGTH

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
    for /f "delims=" %%j in ("!EXECUTABLE_COMMANDS[%%i]!") do @echo %%i^) !_app_name! [%%~nxj]
)

set /P _app_index="app-index> "

set "_app_path=!EXECUTABLE_COMMANDS[%_app_index%]!"

if "%_app_path%"=="" (
    echo Invalid app index
    echo [Process stopped]
    goto back
)

call "%_app_path%"

echo [Completed]
goto back

endlocal

:back
cd /d %PWD%
