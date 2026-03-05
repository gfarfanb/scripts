@echo OFF

setlocal

set __require_var_tag=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%-%RANDOM%_%RANDOM%
set __require_var_bat="%TEMP%\require-var-%__require_var_tag%.bat"
set __require_var_flag=0

echo if "%%%~1%%"=="" ( >> "%__require_var_bat%"
echo echo Undefined environment variable: '%~1' >> "%__require_var_bat%"
echo set __require_var_flag=1 >> "%__require_var_bat%"
echo ) >> "%__require_var_bat%"

call "%__require_var_bat%"
del "%__require_var_bat%"

endlocal & if "%__require_var_flag%"=="1" exit /B 0
