@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\env-vars
call ..\.win\require-var REDIS_HOME
call ..\.win\require-var REDIS_DATA
call ..\.win\require-var REDIS_PORT

goto :main

:__usage_page
echo Starts Redis using binaries.
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto :back

:main
if /i "%~1"=="-h" goto :__usage_page

set _default_opt_index=1

echo Select an option:
echo 1^) ^(default^) Run Redis
echo 2^) Stop Redis
echo 3^) Redis Client

set "_opt_index="
set /P _opt_index="option-index> "
if "%_opt_index%"=="" set _opt_index=%_default_opt_index%

if /i "%_opt_index%"=="1" goto :run
if /i "%_opt_index%"=="2" goto :stop
if /i "%_opt_index%"=="3" goto :client
echo Invalid option index
goto :invalid

:run
cd "%REDIS_HOME%"
RedisService.exe run --foreground --port %REDIS_PORT% --dir "%REDIS_DATA%" --loglevel verbose
goto :completed


:stop
cd %REDIS_HOME%
redis-cli SHUTDOWN
goto :completed


:client
cd "%REDIS_HOME%"
redis-cli
goto :completed


:completed
echo [Completed]: %0
goto :back


:back
cd /d %PWD%
