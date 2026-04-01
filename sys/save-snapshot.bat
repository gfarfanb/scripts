@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\env-vars
call ..\.win\require-var SNAPSHOTS_TO_KEEP

goto :main

:__usage_page
echo Create snapshots of save files.
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% ^<save_home^> [^<option^>]*
echo Option:
echo     -r: Recovers save from snapshots
echo     -h: Displays this help message
goto :eof

:main
set "_saves_home=%~1"

if /i "%~2"=="-r" goto :getsnapshot
if /i "%~1"=="-h" goto :__usage_page
goto :snapshot


:snapshot
python ".\.py\file_snapshot.py" -d "%_saves_home%"
goto :completed

:getsnapshot
python ".\.py\file_snapshot.py" -d "%_saves_home%" --recover
goto :completed

:completed
echo:
echo [Completed]: %0
goto :eof
