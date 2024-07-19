@echo OFF

call env-vars.bat

cd %SNES9X_HOME%

echo Launching 'Snes9x' at "%SNES9X_HOME%"
snes9x-x64.exe

take-snapshot "%SNES9X_BACKUP_HOME%" 000 0A.frz srm oops

cd %PWD%
