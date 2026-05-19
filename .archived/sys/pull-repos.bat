@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\env-vars
call ..\.win\require-var REPOS_DEF_FILE

goto :main

:__usage_page
echo Synchronize local repos.
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto :back

:main
if /i "%~1"=="-h" goto :__usage_page

setlocal enableDelayedExpansion

set /a _repo_idx=1

for /f "tokens=*" %%l in (%REPOS_DEF_FILE%) do (
    call ..\.win\eval set "_repo=%%l"

    set _execute_flag=true

    echo !_repo! | findstr /r /i "^p:.*" >nul

    if !errorlevel! equ 0 (
        set "_repo=!_repo:~2!"
        set _execute_flag=false
    )

    for /f "tokens=1,2 delims=:" %%a in ("!_repo!") do (
        set "_branch=%%a"
        set "_username=%%b"
    )

    set "_prefix=!_branch!:!_username!:"

    call ..\.win\length "!_prefix!" _prefix_length
    call ..\.win\eval set "_location=%%_repo:~!_prefix_length!%%"

    for /f %%i in ("!_location!") do set "_repo_name=%%~ni"

    if "!_execute_flag!"=="false" (
        set "_print_repos[!_repo_idx!]=[!_branch!] !_location!"
        set /a _repo_idx+=1
    ) else (
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

endlocal


:completed
echo:
echo [Completed]: %0
goto :back


:back
cd /d %PWD%
