@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\.libs\env-vars
call ..\.win\require-var WORKSPACE_HOME
call ..\.win\require-var SYS_CONTROL_DB_FILE
call ..\.win\require-var MACHINE_CONTROL_NAME
call ..\.win\require-var OS_CONTROL_NAME
call ..\.win\require-var SESSION_TEMP_DIR

goto :main

:__usage_page
echo Update packages and execute a plan.
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto :back

:main
setlocal enableDelayedExpansion
if /i "%~1"=="-h" goto :__usage_page


systeminfo

set __update_plan_tag=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%-%RANDOM%_%RANDOM%
set __update_plan_bat="%SESSION_TEMP_DIR%\update_plan-%__update_plan_tag%.bat"

python ".\.py\update_plan.py" -s batch -f "%__update_plan_bat%"

call "%__update_plan_bat%"

if exist "%__update_plan_bat%" del "%__update_plan_bat%"

goto :completed

endlocal


:completed
echo:
echo [Completed]: %0
goto :back


:stopped
echo:
echo [Process stopped]: %0
goto :back


:back
cd /d %PWD%
goto :eof
