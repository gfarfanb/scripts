@echo OFF
set PWD=%cd%

call env-vars.bat
call require-var CERTIFICA_HOME
call require-var CERTIFICA_REQUIRED_JDK

call setup-jdk "%CERTIFICA_REQUIRED_JDK%"

cd "%CERTIFICA_HOME%"
"%JAVA_HOME%\bin\java.exe" -jar Certifica.jar

:completed
echo:
echo [Completed]: %0
goto back


:back
cd /d %PWD%
