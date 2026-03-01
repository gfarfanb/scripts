@echo OFF
set PWD=%cd%

call env-vars.bat
call require-var PKHEX_HOME
call require-var PKHEX_RELEASE_HOME

goto main

:usage
echo Starts Pokémon save file editor
echo ;
echo Usage: %0 <save_home> [^<option^>]*
echo Option:
echo     -b: Builds the executable
echo     -h: Displays this help message
goto :eof

:main
if /i "%~1"=="-b" (
    goto build
)
if /i "%~1"=="-h" goto usage
goto execute


:build
cd "%PKHEX_HOME%"

dotnet publish PKHeX.sln -r win-x64 /p:IncludeNativeLibrariesForSelfExtract=true
goto completed


:execute
cd "%PKHEX_RELEASE_HOME%"

PKHeX.exe
goto completed


:completed
echo:
echo [Completed]: %0
goto back


:back
cd /d %PWD%
