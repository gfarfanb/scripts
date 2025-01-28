@echo OFF
set PWD=%cd%

call env-vars.bat
call require-var EXECUTABLE_EXECS_LENGTH

for /l %%i in (1,1,%EXECUTABLE_EXECS_LENGTH%) do (
    call require-var EXECUTABLE_NAMES[%%i]
    call require-var EXECUTABLE_EXECS[%%i]
)

goto main

:usage
echo Launches an executable file.
echo:
echo Usage: %0 [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto back

:main
if /i "%1"=="-h" goto usage

setlocal enableDelayedExpansion

echo Select an executable:
for /l %%i in (1,1,%EXECUTABLE_EXECS_LENGTH%) do (
    set "_app_name=!EXECUTABLE_NAMES[%%i]!"

    for /f "delims=" %%j in ("!EXECUTABLE_EXECS[%%i]!") do (
        if exist %%j (
            echo %%i^) !_app_name! [%%j]
        ) else (
            echo %%i^) ^(not found^) !_app_name!
        )
    )
)

set "_app_index="
set /P _app_index="app-index> "

set "_app_exec=!EXECUTABLE_EXECS[%_app_index%]!"

if "%_app_exec%"=="" (
    echo Invalid app index
    echo [Process stopped]: %0
    goto back
)

if not exist "%_app_exec%" (
    echo '!EXECUTABLE_NAMES[%_app_index%]!' executable not found
    echo [Process stopped]: %0
    goto back
)

for /f "delims=" %%j in ("%_app_exec%") do (
    cd "%%~dpj"
    "%%~nxj"
)

endlocal


:completed
echo [Completed]: %0
goto back


:back
cd /d %PWD%
