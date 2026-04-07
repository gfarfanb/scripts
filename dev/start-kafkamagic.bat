@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\env-vars
call ..\.win\require-var KAFKA_MAGIC_HOME

goto :main

:__usage_page
echo Starts Kafka Magic using binaries.
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto :back

:main
if /i "%~1"=="-h" goto :__usage_page

echo:
echo To change the port number edit parameter 'CONFIG_PORT' in:
echo '%KAFKA_MAGIC_HOME%\appsettings.json'
echo:

cd %KAFKA_MAGIC_HOME%

KafkaMagic
goto :completed


:completed
echo [Completed]: %0
goto :back


:back
cd /d %PWD%
