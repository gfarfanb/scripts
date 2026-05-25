@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\.libs\env-vars
call ..\.win\require-var CERTIFICA_HOME
call ..\.win\require-var CERTIFICA_REQUIRED_JDK

call ..\dev\setup-jdk "%CERTIFICA_REQUIRED_JDK%"

goto :main

:__usage_page
echo Starts Certifica using binaries.
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto :back

:main
if /i "%~1"=="-h" goto :__usage_page

cd "%CERTIFICA_HOME%"
"%JAVA_HOME%\bin\java.exe" -jar Certifica.jar
goto :completed

:completed
echo:
echo [Completed]: %0
goto :back


:back
cd /d %PWD%
