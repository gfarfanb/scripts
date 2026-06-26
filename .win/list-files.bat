@echo OFF

rem __usage_lib_page:
rem Saves the string length into a variable
rem
rem Arguments:
rem   %1 - Directory path
rem   %2 - Text to find in file
rem   %3 - File extension
rem Usage in script:
rem   call %SCRIPTS_HOME%\.win\list-files <dir> <text> <ext>

setlocal enableDelayedExpansion

for /f "delims=" %%F in ('fd . "%1" -e "%3"') do (
    rg --quiet "%2" "%%F" && echo %%F
)

endlocal
