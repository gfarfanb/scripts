@echo OFF

call env-vars
call require-var OPENCODE_SERVER_PORT

goto main

:usage
echo Starts OpenCode server.
echo:
echo Usage: %0 [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto back


:main
if /i "%~1"=="-h" goto usage

opencode serve --port %OPENCODE_SERVER_PORT% --hostname 0.0.0.0
goto completed


:completed
echo:
echo [Completed]: %0
goto back


:back
cd /d %PWD%
