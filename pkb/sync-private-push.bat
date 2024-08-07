@echo OFF

rem Pushes all changes from pkb/org-roam/private directory to a backup folder (preferable a hosting service folder)

call env-vars.bat
call require-var SYNC_FOLDER_PRIVATE_DIR
call require-var ORG_ROAM_PRIVATE_DIR

robocopy "%ORG_ROAM_PRIVATE_DIR%" "%SYNC_FOLDER_PRIVATE_DIR%" /e /z

echo Sync private push completed

