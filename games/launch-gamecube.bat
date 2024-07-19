@echo OFF

call env-vars.bat

cd %DOLPHIN_HOME%

echo Launching 'Dolphin' at "%DOLPHIN_HOME%"
Dolphin.exe

take-snapshot "%DOLPHIN_BACKUP_HOME%" gci

cd %PWD%
