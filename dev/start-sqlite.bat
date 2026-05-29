@echo OFF
set "SOURCEDIR=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\.libs\env-vars
call ..\.win\require-var SQLITE_DBS_HOME

goto :main

:__usage_page
echo Starts SQLite on a selected db.
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -n: Creates a new SQLite database file
echo     -h: Displays this help message
goto :back

:main
setlocal enableDelayedExpansion
if /i "%~1"=="-n" goto :createdb
if /i "%~1"=="-h" goto :__usage_page
goto :selectdb


:createdb
echo Enter the database filename:
set /P _db_filename="db-filename> "

if "%_db_filename%"=="" (
    echo Invalid database name
    goto :stopped
)

set "_db=%SQLITE_DBS_HOME%\%_db_filename%.db"

echo:
echo Creating database...

sqlite3 "%_db%" ".databases"

goto :completed


:selectdb
set /a _idx=1
for /f "delims=" %%G in ('dir %SQLITE_DBS_HOME%\*.db /b') do (
    set _db_filename[!_idx!]=%%~G
    set /a _idx+=1
)
set /a _loaded_db_count=%_idx%-1

echo Select a database:
for /L %%j in (1,1,%_loaded_db_count%) do (
    echo %%j^) !_db_filename[%%j]!
)
set "_db_idx="
set /P _db_idx="db-index> "

set _db=!_db_filename[%_db_idx%]!

if "%_db%"=="" (
    echo Invalid database index
    goto :stopped
)

echo:
echo Opening database: %_db%

sqlite3 "%SQLITE_DBS_HOME%\%_db%"

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
