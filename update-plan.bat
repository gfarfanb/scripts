@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call .\env-vars
call .\.win\require-var WORKSPACE_HOME
call .\.win\require-var UPDATE_PLAN_FILE

goto :main

:__usage_page
echo Update packages and execute a plan.
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto :back

:main
if /i "%~1"=="-h" goto :__usage_page

setlocal enableDelayedExpansion

set /a _cmd_idx=1

for /f "tokens=*" %%l in (%UPDATE_PLAN_FILE%) do (
    call .\.win\eval set "_cmd=%%l"

    echo !_cmd! | findstr /r "^p:*" >nul

    if !errorlevel! equ 0 (
        set "_cmd=!_cmd:~2!"

        set "_print_cmds[!_cmd_idx!]=!_cmd!"
        set /a _cmd_idx+=1
    ) else (
        echo:
        echo Executing: [!_cmd!]

        call .\.win\eval !_cmd!
    )
)

set /a _cmd_count=%_cmd_idx%-1

if %_cmd_count% gtr 0 (
    echo:
    echo Execute these update commands if needed:

    for /L %%i in (1,1,%_cmd_count%) do (
        echo ^> !_print_cmds[%%i]!
    )
)

endlocal


:completed
echo:
echo [Completed]: %0
goto :back


:back
cd /d %PWD%
