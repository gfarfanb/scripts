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
echo     -h: Displays this help message
goto back

:main
if /i "%1"=="-h" goto usage

echo Backing up repos at "%REPOS_HOME%"

setlocal enableDelayedExpansion

cd /d %REPOS_HOME%

for /F "tokens=1,2" %%i in (%REPOS_LIST_FILE%) do (
    set "__repo_zip=%%i.zip"
    set "__repo_url=%%j"

    echo:
    echo Output: !__repo_zip!
    echo URL: !__repo_url!
    curl -L --create-dirs -o !__repo_zip! !__repo_url!
)

echo [Completed]: %0
goto back

endlocal

:back
cd /d %PWD%
