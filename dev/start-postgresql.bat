@echo OFF
set "SOURCEDIR=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\.libs\env-vars
call ..\.win\require-var POSTGRESQL_HOME
call ..\.win\require-var POSTGRESQL_BACKUP_HOME

rem https://blog.marcnuri.com/windows-postgresql-without-installation-portable

goto :main

:__usage_page
echo Starts PostgreSQL database using binaries.
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -c: Starts PostgreSQL initialization
echo     -s: Stops PostgreSQL server
echo     -i: Import a database file
echo     -b: Backup a database
echo     -h: Displays this help message
goto :back

:main
setlocal enableDelayedExpansion
if /i "%~1"=="-c" goto :initialization
if /i "%~1"=="-s" goto :stop
if /i "%~1"=="-i" goto :import
if /i "%~1"=="-b" goto :backup
if /i "%~1"=="-h" goto :__usage_page
goto :run


:initialization
cd %POSTGRESQL_HOME%
bin\initdb.exe -D data -U postgres -W -E UTF8 -A scram-sha-256
goto :completed


:run
cd %POSTGRESQL_HOME%
bin\pg_ctl.exe start -D data
goto :completed


:stop
cd %POSTGRESQL_HOME%
bin\pg_ctl.exe stop -D data
goto :completed


:import
cd %POSTGRESQL_HOME%

echo Importing database:

set /P _db_file="db-file-path> "
if not exist "%_db_file%" (
    echo Invalid DB file: "%_db_file%"
    goto :stopped
)

bin\psql -U postgres -f "%_db_file%"
goto :completed


:backup
cd %POSTGRESQL_HOME%

echo Select a database:
for /L %%l in (1,1,%POSTGRESQL_DATABASE_NAMES_LENGTH%) do (
    echo %%l^) !POSTGRESQL_DATABASE_NAMES[%%l]!
)

set "_database_idx="
set /P _database_idx="database-index> "
set _database_name=!POSTGRESQL_DATABASE_NAMES[%_database_idx%]!
set _database_username=!POSTGRESQL_DATABASE_USERNAMES[%_database_idx%]!

if "%_database_name%"=="" (
    echo Invalid database index
    goto :stopped
)

set "_backup_file=%POSTGRESQL_BACKUP_HOME%\%_database_name%.sql"

bin\pg_dump.exe -U "%_database_username%" -d "%_database_name%" > "%_backup_file%"

echo Backup generated: "%_backup_file%"

call %SCRIPTS_HOME%\sys\save-snapshot -s "%_backup_file%" -k 3

goto :completed


endlocal


:completed
echo:
echo [Completed]: %0
goto :back


:stopped
echo:
echo [Process stopped]: %0
goto :back


:back
cd /d %SOURCEDIR%
goto :eof
