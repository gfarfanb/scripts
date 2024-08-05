@echo OFF

set __timestamp=%date%-%time%
set __timestamp=%__timestamp:/=-%
set __timestamp=%__timestamp::=_%
set __timestamp=%__timestamp: =_%
set __timestamp=%__timestamp:.=_%

set __require_var_bat="%TEMP%\require-var-%__timestamp%.bat"

echo if "%%%1%%"=="" ( >> "%__require_var_bat%"
echo echo Undefined environment variable: '%1' >> "%__require_var_bat%"
echo cmd /k >> "%__require_var_bat%"
echo ) >> "%__require_var_bat%"

call "%__require_var_bat%"
del "%__require_var_bat%"
