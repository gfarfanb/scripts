@echo OFF
set PWD=%cd%

call env-vars.bat
call require-var KAFKA_MAGIC_HOME

goto main

:usage
echo Starts Kafka Magic using binaries
echo:
echo Usage: %0 [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto back

:main
if /i "%~1"=="-h" goto usage

echo:
echo To change the port number edit parameter 'CONFIG_PORT' in:
echo '%KAFKA_MAGIC_HOME%\appsettings.json'
echo:

cd %KAFKA_MAGIC_HOME%

KafkaMagic
goto completed


:completed
echo [Completed]: %0
goto back


:back
cd /d %PWD%
