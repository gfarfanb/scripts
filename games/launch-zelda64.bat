@echo OFF

call env-vars.bat

Robocopy "%ZELDA64RECOMPILED_BACKUP_HOME%" "%ZELDA64RECOMPILED_SAVES_HOME%" /z

cd %ZELDA64RECOMPILED_HOME%

echo Launching 'Zelda 64: Recompiled' at "%ZELDA64RECOMPILED_HOME%"
Zelda64Recompiled.exe

Robocopy "%ZELDA64RECOMPILED_SAVES_HOME%" "%ZELDA64RECOMPILED_BACKUP_HOME%" /z

take-snapshot "%ZELDA64RECOMPILED_BACKUP_HOME%" bin

cd %PWD%
