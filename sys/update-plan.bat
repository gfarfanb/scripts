@echo OFF
set "SOURCEDIR=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\.libs\env-vars
call ..\.win\require-var SYS_CONTROL_DB_FILE
call ..\.win\require-var MACHINE_CONTROL_NAME
call ..\.win\require-var OS_CONTROL_NAME
call ..\.win\require-var SCRIPTS_TEMP_DIR

goto :main

:__usage_page
echo Execute the update plan using batch.
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -a: Accept all commands
echo     -s: Start plan from specific command
echo     -o: Select and execute a command
echo     -h: Displays this help message
goto :back

:main
setlocal enableDelayedExpansion
set "_accept="
set "_mode=all"
if /i "%~1"=="-a" set "_accept=--accept"
if /i "%~2"=="-a" set "_accept=--accept"
if /i "%~1"=="-s" set "_mode=start-from"
if /i "%~1"=="-o" set "_mode=only-one"
if /i "%~1"=="-h" goto :__usage_page

del /q "%SCRIPTS_TEMP_DIR%\update_plan*"
del /q "%SCRIPTS_TEMP_DIR%\cmd-batch.*"

set __update_plan_tag=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%-%RANDOM%_%RANDOM%
set __update_plan_bat="%SCRIPTS_TEMP_DIR%\update_plan-%__update_plan_tag%.bat"

python ".\.py\update_plan.py" -t batch ^
    -n "%MACHINE_CONTROL_NAME%" -o "%OS_CONTROL_NAME%" ^
    -f "%__update_plan_bat%" -m "%_mode%" %_accept%

endlocal & call "%__update_plan_bat%" & if exist "%__update_plan_bat%" del "%__update_plan_bat%"


:completed
echo:
echo [Completed]: %0
goto :back


:stopped
echo:
echo [Process stopped]: %0
goto :back


:back
cd /d %SOURCEDIR%
goto :eof
