@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\env-vars

goto :main

:__usage_page
echo Creates directories based on 'env-vars' file.
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto :back

:main
if /i "%~1"=="-h" goto :__usage_page

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
    if not exist "%WORKSPACE_HOME%\github" (
        mkdir "%WORKSPACE_HOME%\github"
        echo Created directory '%WORKSPACE_HOME%\github'
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
    if not exist "%STORAGE_HOME%\llm" (
        mkdir "%STORAGE_HOME%\llm"
        echo Created directory '%STORAGE_HOME%\models'
    )
    if not exist "%STORAGE_HOME%\devices" (
        mkdir "%STORAGE_HOME%\devices"
        echo Created directory '%STORAGE_HOME%\devices'
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
    if not exist "%MEDIA_HOME%" (
        mkdir "%MEDIA_HOME%"
        echo Created directory '%MEDIA_HOME%'
    )
)
if not "%YT_DLP_HOME%" == "" (
    if not exist "%YT_DLP_HOME%" (
        mkdir "%YT_DLP_HOME%"
        echo Created directory '%YT_DLP_HOME%'
    )
)
if not "%YT_DLP_AUDIO_OUTPUT_FOLDER%" == "" (
    if not exist "%YT_DLP_AUDIO_OUTPUT_FOLDER%" (
        mkdir "%YT_DLP_AUDIO_OUTPUT_FOLDER%"
        echo Created directory '%YT_DLP_AUDIO_OUTPUT_FOLDER%'
    )
)
if not "%YT_DLP_VIDEO_OUTPUT_FOLDER%" == "" (
    if not exist "%YT_DLP_VIDEO_OUTPUT_FOLDER%" (
        mkdir "%YT_DLP_VIDEO_OUTPUT_FOLDER%"
        echo Created directory '%YT_DLP_VIDEO_OUTPUT_FOLDER%'
    )
)
if not "%ROMS_HOME%" == "" (
    if not exist "%ROMS_HOME%" (
        mkdir "%ROMS_HOME%"
        echo Created directory '%ROMS_HOME%'
    )
)
if not "%OUTPUT_HOME%" == "" (
    if not exist "%OUTPUT_HOME%" (
        mkdir "%OUTPUT_HOME%"
        echo Created directory '%OUTPUT_HOME%'
    )
)
if not "%OUTPUT_AUDIO_HOME%" == "" (
    if not exist "%OUTPUT_AUDIO_HOME%" (
        mkdir "%OUTPUT_AUDIO_HOME%"
        echo Created directory '%OUTPUT_AUDIO_HOME%'
    )
)
if not "%OUTPUT_PARSED_HOME%" == "" (
    if not exist "%OUTPUT_PARSED_HOME%" (
        mkdir "%OUTPUT_PARSED_HOME%"
        echo Created directory '%OUTPUT_PARSED_HOME%'
    )
)
if not "%OUTPUT_TRANSCRIPTS_HOME%" == "" (
    if not exist "%OUTPUT_TRANSCRIPTS_HOME%" (
        mkdir "%OUTPUT_TRANSCRIPTS_HOME%"
        echo Created directory '%OUTPUT_TRANSCRIPTS_HOME%'
    )
)
if not "%OUTPUT_WEB_HOME%" == "" (
    if not exist "%OUTPUT_WEB_HOME%" (
        mkdir "%OUTPUT_WEB_HOME%"
        echo Created directory '%OUTPUT_WEB_HOME%'
    )
)

endlocal


:completed
echo [Completed]: %0
goto :back


:back
cd /d %PWD%
