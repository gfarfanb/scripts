@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\env-vars
call ..\.win\require-var SONARQUBE_SERVER_HOME

goto :main

:__usage_page
echo Starts SonarQube Server using binaries
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto :back

:main
if /i "%~1"=="-h" goto :__usage_page

cd "%SONARQUBE_SERVER_HOME%\bin\windows-x86-64"

StartSonar
goto :completed


:completed
echo [Completed]: %0
goto :back


:back
cd /d %PWD%
