@echo OFF
set "SOURCEDIR=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call %SCRIPTS_HOME%\.libs\env-vars
call %SCRIPTS_HOME%\.win\require-var CALIBRE_HOME

goto :main

:__usage_page
echo Starts Calibre using binaries.
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -e: Starts eBook Editor
echo     -v: Starts eBook Viewer
echo     -h: Displays this help message
goto :back

:main
if /i "%~1"=="-e" goto :editor
if /i "%~1"=="-v" goto :viewer
if /i "%~1"=="-h" goto :__usage_page
goto :calibre


:calibre
cd "%CALIBRE_HOME%"
calibre-portable.exe
goto :completed


:editor
cd "%CALIBRE_HOME%"
ebook-edit-portable.exe
goto :completed


:viewer
cd "%CALIBRE_HOME%"
ebook-viewer-portable.exe
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
