@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\env-vars
call ..\.win\require-var COPILOT_API_PORT

goto :main

:__usage_page
echo Starts Copilot API server for Claude proxy.
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto :back


:main
if /i "%~1"=="-h" goto :__usage_page

copilot-api start --port="%COPILOT_API_PORT%" --claude-code
goto :completed


:completed
echo:
echo [Completed]: %0
goto :back


:back
cd /d %PWD%
