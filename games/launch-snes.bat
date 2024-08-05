@echo OFF

call env-vars.bat
call require-var SNES9X_HOME
call require-var SNES9X_BACKUP_HOME

cd %SNES9X_HOME%

echo Launching 'Snes9x' at "%SNES9X_HOME%"
snes9x-x64.exe

take-snapshot "%SNES9X_BACKUP_HOME%" 000 0A.frz srm oops

cd %PWD%
