@echo OFF
set "SOURCEDIR=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call %SCRIPTS_HOME%\.libs\env-vars

if not defined SNAPSHOTS_TO_KEEP set "SNAPSHOTS_TO_KEEP=1"

goto :main

:__usage_page
echo Create snapshots of save files.
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% ^<directory_or_file^> [^<option^>]*
echo Option:
echo     -s: Source directory or file
echo     -k: Number of the snapshots to keep
echo     -r: Recovers save from snapshots
echo     -h: Displays this help message
goto :eof

:main
set _keep=%SNAPSHOTS_TO_KEEP%
if /i "%~1"=="-s" set "_source=%~2"
if /i "%~3"=="-k" set "_keep=%~4" & goto :snapshot
if /i "%~3"=="-r" goto :getsnapshot
if /i "%~1"=="-h" goto :__usage_page
goto :snapshot


:snapshot
python "%SCRIPTS_HOME%\sys\.py\file_snapshot.py" -s "%_source%" -k %_keep%
goto :completed

:getsnapshot
python "%SCRIPTS_HOME%\sys\.py\file_snapshot.py" -s "%_source%" --recover
goto :completed


:completed
echo:
echo [Completed]: %0
goto :eof
