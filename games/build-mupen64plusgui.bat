@echo OFF
set "SOURCEDIR=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call %SCRIPTS_HOME%\.libs\env-vars
call %SCRIPTS_HOME%\.win\require-var MUPEN64PLUS_GUI_HOME
call %SCRIPTS_HOME%\.win\require-var MUPEN64PLUS_GUI_RELEASE_HOME
call %SCRIPTS_HOME%\.win\require-var MUPEN64PLUS_GUI_LAUNCHER_HOME

goto :main

:__usage_page
echo Builds Mupen64Plus GUI.
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto :eof

:main
if /i "%~1"=="-h" goto :__usage_page
goto :build


:build
cd "%MUPEN64PLUS_GUI_HOME%"

powershell scripts\build.ps1

robocopy "%MUPEN64PLUS_GUI_RELEASE_HOME%" "%MUPEN64PLUS_GUI_LAUNCHER_HOME%" /s /z 
goto :completed


:completed
echo:
echo [Completed]: %0
goto :back


:stopped
echo:
echo [Process stopped]: %0
goto :back


:back
cd /d %SOURCEDIR%
goto :eof
