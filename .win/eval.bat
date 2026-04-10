@echo OFF

rem __usage_lib_page:
rem Executes arguments as a batch scripts
rem
rem Dependencies:
rem   call .\env-vars rem Relative call
rem Usage in script:
rem   call .\.win\eval <arg1> <arg2> <argn> # Relative call

setlocal

set __eval_tag=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%-%RANDOM%_%RANDOM%
set __eval_bat="%TEMP%\eval-%__eval_tag%.bat"

echo %* > "%__eval_bat%"

endlocal & call "%__eval_bat%" & if exist "%__eval_bat%" del "%__eval_bat%"
