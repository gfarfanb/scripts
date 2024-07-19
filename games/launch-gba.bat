@echo OFF

call env-vars.bat

cd %MGBA_HOME%

echo Launching 'mGBA' at "%MGBA_HOME%"
mGBA.exe

take-snapshot "%MGBA_BACKUP_HOME%" sav ss1

cd %PWD%
