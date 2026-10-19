@echo OFF
set "SOURCEDIR=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call %SCRIPTS_HOME%\.libs\env-vars
call %SCRIPTS_HOME%\.win\require-var PKHEX_HOME
call %SCRIPTS_HOME%\.win\require-var PKHEX_RELEASE_HOME
call %SCRIPTS_HOME%\.win\require-var PKHEX_LAUNCHER_HOME

goto :main

:__usage_page
echo Builds Pokémon save file editor.
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
cd "%PKHEX_HOME%"

dotnet publish PKHeX.sln -r win-x64 /p:IncludeNativeLibrariesForSelfExtract=true

robocopy "%PKHEX_RELEASE_HOME%" "%PKHEX_LAUNCHER_HOME%" /s /z 
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
