@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\env-vars
call ..\.win\require-var H2_HOME
call ..\.win\require-var H2_WEB_PORT
call ..\.win\require-var H2_REQUIRED_JDK

goto :main

:__usage_page
echo Starts H2 database using binaries
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto :back

:main
if /i "%~1"=="-h" goto :__usage_page

call .\setup-jdk "%H2_REQUIRED_JDK%"

cd %H2_HOME%

for /F "delims=" %%G in ('dir /b /s "h2*.jar"') do (
    set H2_JAR=%%~G
)

"%JAVA_HOME%\bin\java" -cp "%H2_JAR%;%H2DRIVERS%;%CLASSPATH%" org.h2.tools.Server -webPort %H2_WEB_PORT%

goto :completed

:completed
echo:
echo [Completed]: %0
goto :back


:back
cd /d %PWD%
