@echo OFF
set PWD=%cd%

call env-vars.bat

goto main

:usage
echo Creates directories based on 'env-vars' file.
echo:
echo Usage: %0 [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto back

:main
if /i "%~1"=="-h" goto usage

setlocal enableExtensions

echo Creating directories

if not "%EXECS_HOME%" == "" (
    if not exist "%EXECS_HOME%" (
        mkdir "%EXECS_HOME%"
        echo Created directory '%EXECS_HOME%'
    )
)
if not "%WORKSPACE_HOME%" == "" (
    if not exist "%WORKSPACE_HOME%" (
        mkdir "%WORKSPACE_HOME%"
        echo Created directory '%WORKSPACE_HOME%'
    )
)
if not "%STORAGE_HOME%" == "" (
    if not exist "%STORAGE_HOME%\dist" (
        mkdir "%STORAGE_HOME%\dist"
        echo Created directory '%STORAGE_HOME%\dist'
    )
    if not exist "%STORAGE_HOME%\iso" (
        mkdir "%STORAGE_HOME%\iso"
        echo Created directory '%STORAGE_HOME%\iso'
    )
    if not exist "%STORAGE_HOME%\models" (
        mkdir "%STORAGE_HOME%\models"
        echo Created directory '%STORAGE_HOME%\models'
    )
)
if not "%CLOUD_HOME%" == "" (
    if not exist "%CLOUD_HOME%" (
        mkdir "%CLOUD_HOME%"
        echo Created directory '%CLOUD_HOME%'
    )
)
if not "%REPOS_HOME%" == "" (
    if not exist "%REPOS_HOME%" (
        mkdir "%REPOS_HOME%"
        echo Created directory '%REPOS_HOME%'
    )
)
if not "%MEDIA_HOME%" == "" (
    if not exist "%MEDIA_HOME%\dlp" (
        mkdir "%MEDIA_HOME%\dlp"
        echo Created directory '%MEDIA_HOME%\dlp'
    )
    
)
if not "%ROMS_HOME%" == "" (
    if not exist "%ROMS_HOME%" (
        mkdir "%ROMS_HOME%"
        echo Created directory '%ROMS_HOME%'
    )
)

endlocal


:completed
echo [Completed]: %0
goto back


:back
cd /d %PWD%
