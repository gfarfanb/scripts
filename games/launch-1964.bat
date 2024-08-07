@echo OFF

call env-vars.bat
call require-var GEPD_1964_HOME
call require-var GEPD_1964_SAVES_HOME
call require-var GEPD_1964_BACKUP_HOME

robocopy "%GEPD_1964_BACKUP_HOME%" "%GEPD_1964_SAVES_HOME%" /z

cd %GEPD_1964_HOME%

echo Launching '1964 GEPD Edition' at "%GEPD_1964_HOME%"
1964.exe

robocopy "%GEPD_1964_SAVES_HOME%" "%GEPD_1964_BACKUP_HOME%" /z

take-snapshot "%GEPD_1964_BACKUP_HOME%" eep

cd %PWD%
