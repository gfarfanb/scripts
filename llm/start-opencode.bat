@echo OFF
set "SOURCEDIR=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call %SCRIPTS_HOME%\.libs\env-vars
call %SCRIPTS_HOME%\.win\require-var OPENCODE_SERVER_PORT

goto :main

:__usage_page
echo Starts OpenCode as server.
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -s: Starts OpenCode as server
echo     -h: Displays this help message
goto :back


:main
if /i "%~1"=="-s" goto :server
if /i "%~1"=="-h" goto :__usage_page
goto :tui

:server
echo Starting OpenCode as server...
opencode serve --port %OPENCODE_SERVER_PORT% --hostname 0.0.0.0
goto :completed

:tui
echo Starting OpenCode as TUI...
opencode
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
