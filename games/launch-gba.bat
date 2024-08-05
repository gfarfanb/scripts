@echo OFF

call env-vars.bat
call require-var MGBA_HOME
call require-var MGBA_BACKUP_HOME

cd %MGBA_HOME%

echo Launching 'mGBA' at "%MGBA_HOME%"
mGBA.exe

take-snapshot "%MGBA_BACKUP_HOME%" sav ss1

cd %PWD%
