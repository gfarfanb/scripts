@echo OFF
set PWD=%cd%

call env-vars.bat
call require-var EMACS_HOME
rem Last assigned: 5
call require-var EMACS_WAIT_SECS

goto main

:usage
echo Starts Emacs editor.
echo:
echo Usage: %0 [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto back

:main
if /i "%~1"=="-h" goto usage

cd %EMACS_HOME%

tasklist | find /i "runemacs.exe" && goto client || goto server


:server
echo Launching 'Emacs Server' at "%EMACS_HOME%"
runemacs.exe --daemon

timeout %EMACS_WAIT_SECS% > NUL
goto client


:client
echo Launching 'Emacs Client' at "%EMACS_HOME%"
emacsclientw.exe -create-frame --alternate-editor=""
goto completed


:completed
echo [Completed]: %0
goto back


:back
cd /d %PWD%
