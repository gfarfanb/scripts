@echo OFF

call env-vars
call require-var UPDATE_COMMANDS_FILE

goto main

:usage
echo Update packages, scripts and synchronized files.
echo:
echo Usage: %0 [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto back

:main
if /i "%~1"=="-h" goto usage

setlocal enableDelayedExpansion

set /a _cmd_idx=1

for /f "tokens=*" %%l in (%UPDATE_COMMANDS_FILE%) do (
    call eval set "_cmd=%%l"

    echo !_cmd! | findstr /R "^p:*" >nul

    if !errorlevel! equ 0 (
        set "_cmd=!_cmd:~2!"

        set "_print_cmds[!_cmd_idx!]=!_cmd!"
        set /a _cmd_idx+=1
    ) else (
        echo:
        echo Executing: [!_cmd!]

        rem call eval !_cmd!
    )
)

set /a _repo_idx=1

for /f "tokens=*" %%l in (%UPDATE_REPOS_FILE%) do (
    call eval set "_repo=%%l"

    set _execute_flag=false

    echo !_repo! | findstr /R "^e:*" >nul

    if !errorlevel! equ 0 (
        set "_repo=!_repo:~2!"
        set _execute_flag=true
    )

    for /f "tokens=1,2 delims=:" %%a in ("!_repo!") do (
        set "_branch=%%a"
        set "_username=%%b"
    )

    set "_prefix=!_branch!:!_username!:"

    call length "!_prefix!" _prefix_length
    call eval set "_location=%%_repo:~!_prefix_length!%%"

    for /f %%i in ("!_location!") do set "_repo_name=%%~ni"

    if "!_execute_flag!"=="true" (

        if not exist "!_location!" (
            mkdir "!_location!"
            cd "!_location!"
            cd ..
            rd /s /q "!_location!"

            echo:
            echo "Cloning !_repo_name! ..."

            git clone https://!_username!/!_repo_name!.git
        ) else (
            cd "!_location!"

            echo:
            echo Updating !_repo_name! ...

            git checkout !_branch!
            git pull origin !_branch!
        )
    ) else (
        set "_print_repos[!_repo_idx!]=[!_branch!] !_location!"
        set /a _repo_idx+=1
    )
)

set /a _repo_count=%_repo_idx%-1

if %_repo_count% gtr 0 (
    echo:
    echo Update these repos if needed:

    for /L %%i in (1,1,%_repo_count%) do (
        echo ^> !_print_repos[%%i]!
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
goto back


:back
cd /d %PWD%
