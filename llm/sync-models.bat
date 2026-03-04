@echo OFF
set PWD=%cd%

call env-vars.bat
call require-var OLLAMA_SERVER
call require-var OLLAMA_MODELS_DEF_FILE
call require-var OPENCODE_CONFIG_FILE
call require-var SCRIPTS_LLM_LIBS_HOME

goto main

:usage
echo Synchronizes Ollama models.
echo:
echo Usage: %0 [^<option^>]*
echo Option:
echo     -s: Syncs models with OpenCode configuration file
echo     -h: Displays this help message
goto back


:main
if /i "%~1"=="-s" goto opencode
if /i "%~1"=="-h" goto usage
goto sync

:sync
python "%SCRIPTS_LLM_LIBS_HOME%\pull-models.py" -o "%OLLAMA_SERVER%" -m "%OLLAMA_MODELS_DEF_FILE%"
goto completed

:opencode
python "%SCRIPTS_LLM_LIBS_HOME%\pull-models.py" -o "%OLLAMA_SERVER%" -m "%OLLAMA_MODELS_DEF_FILE%" -c "%OPENCODE_CONFIG_FILE%" --sync
goto completed


:completed
echo:
echo [Completed]: %0
goto back


:back
cd /d %PWD%
