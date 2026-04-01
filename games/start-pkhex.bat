@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\env-vars
call ..\.win\require-var PKHEX_HOME
call ..\.win\require-var PKHEX_RELEASE_HOME

goto :main

:__usage_page
echo Starts Pokémon save file editor
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -b: Builds the executable
echo     -h: Displays this help message
goto :eof

:main
if /i "%~1"=="-b" goto :build
if /i "%~1"=="-h" goto :__usage_page
goto :execute


:build
cd "%PKHEX_HOME%"

dotnet publish PKHeX.sln -r win-x64 /p:IncludeNativeLibrariesForSelfExtract=true
goto :completed


:execute
cd "%PKHEX_RELEASE_HOME%"

PKHeX.exe
goto :completed


:completed
echo:
echo [Completed]: %0
goto :back


:back
cd /d %PWD%
