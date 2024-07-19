@echo OFF

set __timestamp=%date%-%time%
set __timestamp=%__timestamp:/=-%
set __timestamp=%__timestamp::=_%
set __timestamp=%__timestamp: =_%
set __timestamp=%__timestamp:.=_%

set __temp_eval="%TEMP%\eval-%__timestamp%.bat"

echo %* > "%__temp_eval%"
call "%__temp_eval%"
del "%__temp_eval%"
