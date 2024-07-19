@echo OFF

call env-vars.bat

cd %EMACS_HOME%

echo Launching 'Emacs Server' at "%EMACS_HOME%"
runemacs.exe --daemon

cd %PWD%
