@echo OFF
set PWD=%cd%

call env-vars.bat

goto main

:usage
echo Starts jShell on a selected JDK
echo:
echo Usage: %0 [^<jdk_version^>^|^<option^>]*
echo Option:
echo     -h: Displays this help message
goto back

:main
if /i "%~1"=="-h" goto usage

call setup-jdk %*

"%JAVA_HOME%\bin\jshell"
goto completed

:completed
echo:
echo [Completed]: %0
goto back


:back
cd /d %PWD%
