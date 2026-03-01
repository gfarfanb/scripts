@echo OFF

call env-vars.bat
call require-var SNAPSHOTS_TO_KEEP
call require-var SCRIPTS_LIBS_HOME

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
set "_recover_flag="
if /i "%~1"=="-h" goto usage
if /i "%~2"=="-r" set "_recover_flag= --recover"

set "_saves_home=%~1"

python "%SCRIPTS_LIBS_HOME%\file-snapshot.py" -d "%_saves_home%"%_recover_flag%
goto completed

:completed
echo:
echo [Completed]: %0
goto :eof
