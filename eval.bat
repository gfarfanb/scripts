@echo OFF

set __timestamp=%date%-%time%
set __timestamp=%__timestamp:/=-%
set __timestamp=%__timestamp::=_%
set __timestamp=%__timestamp: =_%
set __timestamp=%__timestamp:.=_%

set __eval_bat="%TEMP%\eval-%__timestamp%.bat"

echo %* > "%__eval_bat%"

call "%__eval_bat%"
del "%__eval_bat%"
