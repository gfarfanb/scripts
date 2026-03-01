@echo OFF
set PWD=%cd%

call env-vars.bat
call require-var EIGHTBITDO_FIRMWARE_UPDATER_HOME

goto main

:usage
echo Starts '8BitDo Firmware Updater' program
echo:
echo Usage: %0 [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto back


:main
if /i "%~1"=="-h" goto usage

cd "%EIGHTBITDO_FIRMWARE_UPDATER_HOME%"

"8BitDo Firmware Updater.exe"
goto completed


:completed
echo:
echo [Completed]: %0
goto back


:back
cd /d %PWD%
