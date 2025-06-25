@echo OFF
set PWD=%cd%

call env-vars.bat
call require-var SNAPSHOTS_TO_KEEP
call require-var SCRIPTS_LIBS_HOME

goto main

:usage
echo Create snapshots of save files.
echo ;
echo Usage: %0 [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto back

:main
if /i "%1"=="-h" goto usage

set "_saves_home=%~1"

python "%SCRIPTS_LIBS_HOME%\file-snapshot.py" "%_saves_home%" %SNAPSHOTS_TO_KEEP%
goto completed

:completed
echo:
echo [Completed]: %0
goto back

:back
cd /d %PWD%
