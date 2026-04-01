@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\env-vars
call ..\.win\require-var JD_GUI_JAR

goto :main

:__usage_page
echo Starts JD-GUI using binaries
echo:
echo Usage: %0 [^<jdk_version^>^|^<option^>]*
echo Option:
echo     -h: Displays this help message
goto :back

:main
if /i "%~1"=="-h" goto :__usage_page

call .\setup-jdk %*

"%JAVA_HOME%\bin\java" -jar "%JD_GUI_JAR%"
goto :completed


:completed
echo:
echo [Completed]: %0
goto :back


:back
cd /d %PWD%
