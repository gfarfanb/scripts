@echo OFF

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
