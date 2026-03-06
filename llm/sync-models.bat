@echo OFF

call env-vars
call require-var OLLAMA_SERVER
call require-var OLLAMA_MODELS_DEF_FILE
call require-var OPENCODE_CONFIG_FILE
call require-var SCRIPTS_PY_HOME

goto main

:usage
echo Synchronizes Ollama models and updates OpenCode configuration.
echo:
echo Usage: %0 [^<option^>]*
echo Option:
echo     -s: Only syncs models on OpenCode configuration file
echo     -h: Displays this help message
goto back


:main
if /i "%~1"=="-s" goto opencode
if /i "%~1"=="-h" goto usage
goto sync

:sync
python "%SCRIPTS_PY_HOME%\ollama_models.py" -a opencode
goto completed

:opencode
python "%SCRIPTS_PY_HOME%\ollama_models.py" -a opencode --sync
goto completed


:completed
echo:
echo [Completed]: %0
goto back


:back
cd /d %PWD%
