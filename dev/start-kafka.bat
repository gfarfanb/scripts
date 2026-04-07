@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\env-vars
call ..\.win\require-var KAFKA_HOME
call ..\.win\require-var KAFKA_KRAFT_HOME
call ..\.win\require-var KAFKA_REQUIRED_JDK

goto :main

:__usage_page
echo Starts Apache Kafka using binaries.
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto :back

:main
if /i "%~1"=="-h" goto :__usage_page

call .\setup-jdk "%KAFKA_REQUIRED_JDK%"

set _default_opt_index=2

echo Select an option:
echo 1^) Kafka initialization
echo 2^) ^(default^) Run Kafka

set "_opt_index="
set /P _opt_index="option-index> "
if "%_opt_index%"=="" set _opt_index=%_default_opt_index%

if /i "%_opt_index%"=="1" goto :initialization
if /i "%_opt_index%"=="2" goto :run
goto :invalid


:initialization
echo Removing old files...
del /s /q %KAFKA_KRAFT_HOME%\*
for /d %%x in (%KAFKA_KRAFT_HOME%\*) do rd /s /q "%%x"

cd %KAFKA_HOME%
echo bin\windows\kafka-storage format --standalone -t kafkastore -c config\server.properties
bin\windows\kafka-storage format --standalone -t kafkastore -c config\server.properties
goto :completed


:run
cd %KAFKA_HOME%
bin\windows\kafka-server-start config\server.properties
goto :completed


:invalid
echo Invalid option index
echo [Process invalid]: %0
goto :back


:completed
echo [Completed]: %0
goto :back


:back
cd /d %PWD%
