@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\env-vars
call ..\.win\require-var CERTIFICA_HOME
call ..\.win\require-var CERTIFICA_REQUIRED_JDK

call ..\dev\setup-jdk "%CERTIFICA_REQUIRED_JDK%"

cd "%CERTIFICA_HOME%"
"%JAVA_HOME%\bin\java.exe" -jar Certifica.jar
goto :completed

:completed
echo:
echo [Completed]: %0
goto :back


:back
cd /d %PWD%
