@echo OFF

call env-vars
call require-var SNAPSHOTS_TO_KEEP
call require-var SCRIPTS_PY_HOME

goto main

:usage
echo Create snapshots of save files.
echo ;
echo Usage: %0 <save_home> [^<option^>]*
echo Option:
echo     -r: Recovers save from snapshots
echo     -h: Displays this help message
goto :eof

:main
set "_saves_home=%~1"

if /i "%~2"=="-r" goto getsnapshot
if /i "%~1"=="-h" goto usage
goto snapshot

:snapshot
python "%SCRIPTS_PY_HOME%\file_snapshot.py" -d "%_saves_home%"
goto completed

:getsnapshot
python "%SCRIPTS_PY_HOME%\file_snapshot.py" -d "%_saves_home%" --recover
goto completed

:completed
echo:
echo [Completed]: %0
goto :eof
