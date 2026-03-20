@echo OFF

call env-vars
call require-var SCRIPTS_SYS_PY_HOME

goto main

:usage
echo Pull changes for local repos or clone if they do not exist.
echo:
echo Usage: %0 [^<option^>]*
echo Option:
echo     -b: Backup repos as ZIP files
echo     -s: Allow select a repo
echo     -h: Displays this help message
goto back

:main
if /i "%~1"=="-h" goto usage

python "%SCRIPTS_SYS_PY_HOME%\backup_repos.py" %*
goto completed


:completed
echo:
echo [Completed]: %0
goto back


:back
cd /d %PWD%
