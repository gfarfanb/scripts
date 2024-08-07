@echo OFF

call env-vars.bat
call require-var REPOS_BACKUP_HOME
call require-var REPOS_LIST_FILE

echo Backing up repos at "%REPOS_BACKUP_HOME%"

setlocal enableDelayedExpansion

cd /d %REPOS_BACKUP_HOME%

for /F "tokens=1,2" %%i in (%REPOS_LIST_FILE%) do (
    set "__repo_zip=%%i.zip"
    set "__repo_url=%%j"

    curl -L --create-dirs -o !__repo_zip! !__repo_url!
)

endlocal

cd /d %PWD%
