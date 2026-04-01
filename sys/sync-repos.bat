@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\env-vars

goto :main

:__usage_page
echo Pull changes for local repos or clone if they do not exist.
echo:
echo Usage: %0 [^<option^>]*
echo Option:
echo     -b: Backup repos as ZIP files
echo     -s: Allow select a repo
echo     -h: Displays this help message
goto :back

:main
if /i "%~1"=="-h" goto :__usage_page

python ".\.py\backup_repos.py" %*
goto :completed


:completed
echo:
echo [Completed]: %0
goto :back


:back
cd /d %PWD%
