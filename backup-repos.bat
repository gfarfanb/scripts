@echo OFF
set PWD=%cd%

call env-vars.bat
call require-var REPOS_HOME
call require-var REPOS_LIST_FILE

goto main

:usage
echo Download the repositories backup.
echo:
echo Usage: %0 [^<option^>]*
echo Option:
echo     -a: Makes a backup for all repos
echo     -h: Displays this help message
goto back

:main
if /i "%1"=="-h" goto usage

echo Backing up repos at "%REPOS_HOME%"

setlocal enableDelayedExpansion

cd /d %REPOS_HOME%

if /i "%1"=="-a" goto allrepos
goto selectrepo

:allrepos
for /F "tokens=1,2" %%i in (%REPOS_LIST_FILE%) do (
    set "__repo_zip=%%i.zip"
    set "__repo_url=%%j"

    echo:
    echo Output: !__repo_zip!
    echo URL: !__repo_url!
    curl -L --create-dirs -o !__repo_zip! !__repo_url!
)
goto completed

:selectrepo

echo:
echo Choose a repo to backup:
set /a _repo_idx=1
for /F "tokens=1,2" %%i in (%REPOS_LIST_FILE%) do (
    echo !_repo_idx!^) %%i
    set /a _repo_idx+=1
)
set /P _selected_idx="repo-index> "

set /a _repo_idx=1
set _repo_flag=false
for /F "tokens=1,2" %%i in (%REPOS_LIST_FILE%) do (

    if "%_selected_idx%"=="!_repo_idx!" (
        set "__repo_zip=%%i.zip"
        set "__repo_url=%%j"

        echo:
        echo Output: !__repo_zip!
        echo URL: !__repo_url!
        curl -L --create-dirs -o !__repo_zip! !__repo_url!

        set _repo_flag=true
    )

    set /a _repo_idx+=1
)

if "%_repo_flag%"=="false" (
    echo Invalid repo index
    echo [Process stopped]: %0
    goto back
)
goto completed

endlocal


:completed
echo [Completed]: %0
goto back


:back
cd /d %PWD%
