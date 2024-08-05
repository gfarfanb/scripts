@echo OFF

:: Fetches all changes from backup folder (preferably a hosting service folder) to the pkb/org-roam/private
:: Required Environment Variables:
::   SYNC_FOLDER_PRIVATE_DIR=C:\...\
::   ORG_ROAM_PRIVATE_DIR=C:\...\pkb\org-roam\private
::   Path=%Path%;%SYNC_FOLDER_PRIVATE_DIR%;%ORG_ROAM_PRIVATE_DIR%

robocopy "%SYNC_FOLDER_PRIVATE_DIR%" "%ORG_ROAM_PRIVATE_DIR%" /e /z 

echo "Sync private pull completed"

