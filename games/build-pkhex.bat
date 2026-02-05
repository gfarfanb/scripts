@echo OFF

call env-vars.bat
call require-var PKHEX_HOME

goto main

:usage
echo Builds PKHeX executable.
echo ;
echo Usage: %0 <save-home> [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto :eof

:main
if /i "%~1"=="-h" goto usage

cd "%PKHEX_HOME%"

dotnet publish PKHeX.sln -r win-x64 /p:IncludeNativeLibrariesForSelfExtract=true
goto completed

:completed
echo:
echo [Completed]: %0
goto :eof
