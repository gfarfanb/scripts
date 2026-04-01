@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\env-vars
call ..\.win\require-var OPENCODE_SERVER_PORT

goto :main

:__usage_page
echo Starts OpenCode server.
echo:
echo Usage: %0 [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto :back


:main
if /i "%~1"=="-h" goto :__usage_page

opencode serve --port %OPENCODE_SERVER_PORT% --hostname 0.0.0.0
goto :completed


:completed
echo:
echo [Completed]: %0
goto :back


:back
cd /d %PWD%
