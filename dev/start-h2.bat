@echo OFF
set PWD=%cd%

call env-vars.bat
call require-var H2_HOME
call require-var H2_WEB_PORT
call require-var H2_REQUIRED_JDK

goto main

:usage
echo Starts H2 database using binaries
echo:
echo Usage: %0 [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto back

:main
if /i "%~1"=="-h" goto usage

cd %H2_HOME%

call setup-jdk "%H2_REQUIRED_JDK%"

for /F "delims=" %%G in ('dir /b /s "h2*.jar"') do (
    set H2_JAR=%%~G
)

"%JAVA_HOME%\bin\java" -cp "%H2_JAR%;%H2DRIVERS%;%CLASSPATH%" org.h2.tools.Server -webPort %H2_WEB_PORT%

goto completed

:completed
echo:
echo [Completed]: %0
goto back


:back
cd /d %PWD%
