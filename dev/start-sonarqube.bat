@echo OFF
set PWD=%cd%

call env-vars.bat
call require-var SONARQUBE_SERVER_HOME

goto main

:usage
echo Starts SonarQube Server using binaries
echo:
echo Usage: %0 [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto back

:main
if /i "%~1"=="-h" goto usage

cd "%SONARQUBE_SERVER_HOME%\bin\windows-x86-64"

StartSonar
goto completed


:completed
echo [Completed]: %0
goto back


:back
cd /d %PWD%
