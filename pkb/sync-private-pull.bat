@echo OFF

rem Fetches all changes from backup folder (preferably a hosting service folder) to the pkb/org-roam/private

call env-vars.bat
call require-var SYNC_FOLDER_PRIVATE_DIR
call require-var ORG_ROAM_PRIVATE_DIR

Robocopy "%SYNC_FOLDER_PRIVATE_DIR%" "%ORG_ROAM_PRIVATE_DIR%" /e /z 

echo Sync private pull completed

cd %PWD%
