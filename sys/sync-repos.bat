@echo OFF
set "SOURCEDIR=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\.libs\env-vars
call ..\.win\require-var SYS_CONTROL_DB_FILE
call ..\.win\require-var MACHINE_CONTROL_NAME
call ..\.win\require-var OS_CONTROL_NAME
call ..\.win\require-var WORKSPACE_HOME
call ..\.win\require-var REPOS_HOME

goto :main

:__usage_page
echo Pull changes for local repos or clone if they do not exist.
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -b: Backup repos as ZIP files
echo     -s: Allow select a repo
echo     -h: Displays this help message
goto :back

:main
if /i "%~1"=="-h" goto :__usage_page

python ".\.py\backup_repos.py" ^
    -n "%MACHINE_CONTROL_NAME%" -o "%OS_CONTROL_NAME%" %*
goto :completed


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
