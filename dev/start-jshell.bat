@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\env-vars

goto :main

:__usage_page
echo Starts jShell on a selected JDK
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<jdk_version^>^|^<option^>]*
echo Option:
echo     -h: Displays this help message
goto :back

:main
if /i "%~1"=="-h" goto :__usage_page

call .\setup-jdk %*

"%JAVA_HOME%\bin\jshell"
goto :completed

:completed
echo:
echo [Completed]: %0
goto :back


:back
cd /d %PWD%
