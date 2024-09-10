@echo OFF

setlocal

set __eval_tag=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%-%TIME::=%-%RANDOM%
set __eval_bat="%TEMP%\eval-%__eval_tag%.bat"

echo %* > "%__eval_bat%"

endlocal & call "%__eval_bat%" & del "%__eval_bat%"
