@echo OFF

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
set /P _prop_index="env-index> "

if "%_prop_index%"=="" (
    echo Invalid environment variable index
    echo [Process stopped]
    goto back
)

set "_prop_name=!_vars[%_prop_index%]!"

if "%_prop_name%"=="" (
    echo Invalid environment variable index
    echo [Process stopped]
    goto back
)

echo:
call eval echo %_prop_name%=%%%%%_prop_name%%%%%
goto completed

:getvar
for %%A in (%~1) do set %2=%%A
goto :eof

endlocal


:completed
echo:
echo [Completed]
goto back


:back
cd %PWD%
