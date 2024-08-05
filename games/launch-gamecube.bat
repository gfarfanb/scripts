@echo OFF

call env-vars.bat
call require-var DOLPHIN_HOME
call require-var DOLPHIN_BACKUP_HOME

cd %DOLPHIN_HOME%

echo Launching 'Dolphin' at "%DOLPHIN_HOME%"
Dolphin.exe

take-snapshot "%DOLPHIN_BACKUP_HOME%" gci

cd %PWD%
