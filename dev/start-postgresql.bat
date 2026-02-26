@echo OFF
set PWD=%cd%

call env-vars.bat
call require-var POSTGRESQL_HOME

goto main

:usage
echo Starts PostgreSQL database using binaries
echo:
echo Usage: %0 [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto back

:main
if /i "%~1"=="-h" goto usage

set _default_opt_index=2

echo Select an option:
echo 1^) PostgreSQL initialization
echo 2^) ^(default^) Run PostgreSQL
echo 3^) Stop PostgreSQL
echo 4^) Import database

set "_opt_index="
set /P _opt_index="option-index> "
if "%_opt_index%"=="" set _opt_index=%_default_opt_index%

if /i "%_opt_index%"=="1" goto initialization
if /i "%_opt_index%"=="2" goto run
if /i "%_opt_index%"=="3" goto stop
if /i "%_opt_index%"=="4" goto import
echo Invalid option index
goto invalid

:initialization
cd %POSTGRESQL_HOME%
bin\initdb.exe -D data -U postgres -W -E UTF8 -A scram-sha-256
goto completed


:run
cd %POSTGRESQL_HOME%
bin\pg_ctl.exe start -D data
goto completed


:stop
cd %POSTGRESQL_HOME%
bin\pg_ctl.exe stop -D data
goto completed


:import
cd %POSTGRESQL_HOME%

echo Importing database:

set /P _db_file="db-file-path> "
if "%_db_file%"=="" (
    echo Invalid DB file
    goto invalid
)

bin\psql -U postgres -f "%_db_file%"
goto completed


:invalid
echo [Process invalid]: %0
goto back


:completed
echo:
echo [Completed]: %0
goto back


:back
cd /d %PWD%
