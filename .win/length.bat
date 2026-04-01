@echo OFF

rem __usage_lib_page:
rem Saves the string length into a variable
rem
rem Arguments:
rem   %1 - String value
rem   %2 - Output variable
rem Usage in script:
rem   call .\.win\length <value> <var> # Relative call

setlocal

set "__input=%1"
set __input=!__input:"=!
set /a __length=0

:stringlengthloop
if defined __input (
    set "__input=!__input:~1!"
    set /a __length+=1
    goto :stringlengthloop
)

endlocal & set /a "%2=%__length%"
