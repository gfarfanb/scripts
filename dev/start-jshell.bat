@echo OFF
set PWD=%cd%

call env-vars.bat

call setup-jdk

"%JAVA_HOME%\bin\jshell"
goto completed

:completed
echo:
echo [Completed]: %0
goto back


:back
cd /d %PWD%
