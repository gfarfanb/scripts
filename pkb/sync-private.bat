@echo OFF

call env-vars.bat
call require-var SYNC_FOLDER_PRIVATE_DIR
call require-var ORG_ROAM_PRIVATE_DIR

goto main

:usage
echo Fetches all changes from backup folder (preferably a
echo hosting service folder) to the pkb/org-roam/private
echo:
echo Usage: %0 [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto back


:main
if /i "%1"=="-h" goto usage

echo Select an operation:
echo 1^) Pull
echo 2^) Push
set /P _op_index="operation-index> "

if "%_op_index%"=="" (
    goto invalid
)

if /i "%_op_index%"=="1" goto pull
if /i "%_op_index%"=="2" goto push
goto invalid


:pull
echo Pulling changes from '%SYNC_FOLDER_PRIVATE_DIR%'
robocopy "%SYNC_FOLDER_PRIVATE_DIR%" "%ORG_ROAM_PRIVATE_DIR%" /e /z 
goto completed


:push
echo Pushing changes to '%SYNC_FOLDER_PRIVATE_DIR%'
robocopy "%ORG_ROAM_PRIVATE_DIR%" "%SYNC_FOLDER_PRIVATE_DIR%" /e /z
goto completd


:invalid
echo Invalid operation index
echo [Process stopped]
goto back


:completed
echo [Completed]
goto back


:back
cd %PWD%
