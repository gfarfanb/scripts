@echo OFF

call env-vars.bat

Robocopy "%PERFECTDARK_BACKUP_HOME%" "%PERFECTDARK_SAVES_HOME%" /z

cd %PERFECTDARK_HOME%

echo Launching 'perfect_dark' at "%PERFECTDARK_HOME%"
pd.exe --rom-file "%PERFECTDARK_ROM%"

Robocopy "%PERFECTDARK_SAVES_HOME%" "%PERFECTDARK_BACKUP_HOME%" eeprom.bin /z

take-snapshot "%PERFECTDARK_BACKUP_HOME%" bin

cd %PWD%
