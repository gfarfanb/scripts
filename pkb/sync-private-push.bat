@echo OFF

:: Pushes all changes from pkb/org-roam/private directory to a backup folder (preferable a hosting service folder)
:: Required Environment Variables:
::   SYNC_FOLDER_PRIVATE_DIR=C:\...\
::   ORG_ROAM_PRIVATE_DIR=C:\...\pkb\org-roam\private
::   Path=%Path%;%SYNC_FOLDER_PRIVATE_DIR%;%ORG_ROAM_PRIVATE_DIR%

robocopy "%ORG_ROAM_PRIVATE_DIR%" "%SYNC_FOLDER_PRIVATE_DIR%" /e /z

echo "Sync private push completed"

