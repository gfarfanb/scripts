@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\env-vars
call ..\.win\require-var EIGHTBITDO_FIRMWARE_UPDATER_HOME

goto :main

:__usage_page
echo Starts '8BitDo Firmware Updater' app using binaires.
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto :back


:main
if /i "%~1"=="-h" goto :__usage_page

cd "%EIGHTBITDO_FIRMWARE_UPDATER_HOME%"

"8BitDo Firmware Updater.exe"
goto :completed


:completed
echo:
echo [Completed]: %0
goto :back


:back
cd /d %PWD%
