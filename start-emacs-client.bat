@echo OFF

:: Emacs Client
:: Launch a new instance of Emacs client
:: Pre-conditions:
::   Run start-emacs-server.bat

call env-vars.bat
call require-var EMACS_HOME

cd %EMACS_HOME%

echo Launching 'Emacs Client' at "%EMACS_HOME%"
emacsclientw.exe -create-frame --alternate-editor=""

cd %PWD%
