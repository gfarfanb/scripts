@echo OFF

call env-vars.bat
call require-var PERFECTDARK_HOME
call require-var PERFECTDARK_ROM
call require-var PERFECTDARK_SAVES_HOME
call require-var PERFECTDARK_BACKUP_HOME

Robocopy "%PERFECTDARK_BACKUP_HOME%" "%PERFECTDARK_SAVES_HOME%" /z

cd %PERFECTDARK_HOME%

echo Launching 'perfect_dark' at "%PERFECTDARK_HOME%"
pd.exe --rom-file "%PERFECTDARK_ROM%"

Robocopy "%PERFECTDARK_SAVES_HOME%" "%PERFECTDARK_BACKUP_HOME%" eeprom.bin /z

take-snapshot "%PERFECTDARK_BACKUP_HOME%" bin

cd %PWD%
