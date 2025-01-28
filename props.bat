@echo OFF
set PWD=%cd%

call env-vars.bat

goto main

:usage
echo Show the environment variables defined in the 'env-vars' file.
echo:
echo Usage: %0 [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto back

:main
if /i "%1"=="-h" goto usage

setlocal enableDelayedExpansion

set /a _var_idx=1

for /f "tokens=*" %%l in (%ENV_VARS_FILE%) do (
    echo %%l | findstr /R "^set.*" >nul

    if !errorlevel! equ 0 (
        for /F "tokens=1 delims=\=" %%j in ("%%l") do (
            set "_line=%%j"
            set _line=!_line:"=!

            call :getvar "!_line!" _var

            set "_vars[!_var_idx!]=!_var!"
            set /a _var_idx+=1
        )
    )
)

set /a _loaded_var_count=%_var_idx%-1

echo Select an environment variable:
for /L %%i in (1,1,%_loaded_var_count%) do (
    echo %%i^) !_vars[%%i]!
)
set "_prop_index="
set /P _prop_index="env-index> "

if "%_prop_index%"=="" (
    echo Invalid environment variable index
    echo [Process stopped]: %0
    goto back
)

set "_prop_name=!_vars[%_prop_index%]!"

if "%_prop_name%"=="" (
    echo Invalid environment variable index
    echo [Process stopped]: %0
    goto back
)

echo:
call eval set "_prop_value=%%%_prop_name%%%"

if "!_prop_value!"=="" (
    echo !_prop_name!=^<empty^>
) else (
    echo !_prop_name!=!_prop_value!
)

echo !_prop_value! | clip
echo Copied^^!^^!

goto completed

:getvar
for %%A in (%~1) do set %2=%%A
goto :eof

endlocal


:completed
echo:
echo [Completed]: %0
goto back


:back
cd /d %PWD%
