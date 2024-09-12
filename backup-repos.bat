@echo OFF
set PWD=%cd%

call env-vars.bat
call require-var REPOS_HOME
call require-var REPOS_LIST_FILE

echo Backing up repos at "%REPOS_HOME%"

setlocal enableDelayedExpansion

cd /d %REPOS_HOME%

for /F "tokens=1,2" %%i in (%REPOS_LIST_FILE%) do (
    set "__repo_zip=%%i.zip"
    set "__repo_url=%%j"

    curl -L --create-dirs -o !__repo_zip! !__repo_url!
)

endlocal

cd /d %PWD%
