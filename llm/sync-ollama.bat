@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\env-vars
call ..\.win\require-var OLLAMA_SERVER
call ..\.win\require-var OLLAMA_MODELS_DEF_FILE
call ..\.win\require-var OPENCODE_CONFIG_FILE
call ..\.win\require-var PI_CONFIG_FILE

goto :main

:__usage_page
echo Synchronizes Ollama models and updates OpenCode/Pi configuration.
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -c: Only syncs models on OpenCode/Pi configuration file
echo     -h: Displays this help message
goto :back


:main
if /i "%~1"=="-s" goto :sync
if /i "%~1"=="-h" goto :__usage_page
goto :pull

:pull
python ".\.py\ollama_models.py" -a opencode -a pi
goto :completed

:sync
python ".\.py\ollama_models.py" -a opencode -a pi --config
goto :completed


:completed
echo:
echo [Completed]: %0
goto :back


:back
cd /d %PWD%
