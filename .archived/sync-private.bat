@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\env-vars
call ..\.win\require-var SYNC_FOLDER_PRIVATE_DIR
call ..\.win\require-var ORG_ROAM_PRIVATE_DIR

goto :main

:__usage_page
echo Fetches all changes from backup folder (preferably a
echo hosting service folder) to the pkb/org-roam/private
echo:
echo Usage: %0 [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto :back


:main
if /i "%~1"=="-h" goto :__usage_page

echo Select an operation:
echo 1^) Pull
echo 2^) Push
set "_op_index="
set /P _op_index="operation-index> "

if "%_op_index%"=="" (
    goto :invalid
)

if /i "%_op_index%"=="1" goto :pull
if /i "%_op_index%"=="2" goto :push
goto :invalid


:pull
echo Pulling changes from '%SYNC_FOLDER_PRIVATE_DIR%'
robocopy "%SYNC_FOLDER_PRIVATE_DIR%" "%ORG_ROAM_PRIVATE_DIR%" /e /z 
goto :completed


:push
echo Pushing changes to '%SYNC_FOLDER_PRIVATE_DIR%'
robocopy "%ORG_ROAM_PRIVATE_DIR%" "%SYNC_FOLDER_PRIVATE_DIR%" /e /z
goto :completd


:invalid
echo Invalid operation index
echo [Process stopped]: %0
goto :back


:completed
echo [Completed]: %0
goto :back


:back
cd /d %PWD%
