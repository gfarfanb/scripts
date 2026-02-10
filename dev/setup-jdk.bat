@echo OFF
set PWD=%cd%

call env-vars.bat
call require-var JDK_HOMES_FILE

goto main

:usage
echo Shows the JDKs installed based on 'JDK_HOMES_FILE'
echo file and setups the environment variables
echo 'JAVA_HOME' and 'JAVA_JRE_HOME'
echo with the selected JDK.
echo:
echo Usage: %0 [^<jdk-version^>]*
echo Option:
echo     -h: Displays this help message
goto back

:main
if /i "%~1"=="-h" goto usage

call source-file "%JDK_HOMES_FILE%"

setlocal enableDelayedExpansion

set "_JDK_INDEX="

if /i "%~1"=="" goto selectjdk
goto searchjdk

:searchjdk
set "_REQUIRED_JDK=%~1"

for /l %%i in (1,1,%JDK_HOMES_LENGTH%) do (
    set "_JDK_NAME=!JDK_NAMES[%%i]!"
    set "_JDK_VERSION=!JDK_VERSIONS[%%i]!"
    set "_JDK_ALIASES=!JDK_ALIASES[%%i]!"

    if /i "!_JDK_NAME!"=="%_REQUIRED_JDK%" (
        set _JDK_INDEX=%%i
        goto jdkname
    )

    if /i "!_JDK_VERSION!"=="%_REQUIRED_JDK%" (
        set _JDK_INDEX=%%i
        goto jdkname
    )

    if /i not "x!_JDK_ALIASES:%_REQUIRED_JDK%=!"=="x!_JDK_ALIASES!" (
        set _JDK_INDEX=%%i
        goto jdkname
    )
)
goto jdkname

:selectjdk
echo Select a JDK:
for /l %%i in (1,1,%JDK_HOMES_LENGTH%) do (
    set "_JDK_NAME=!JDK_NAMES[%%i]!"

    for /f "delims=" %%j in ("!JDK_HOMES[%%i]!") do (
        if "%%i"=="%JDK_DEFAULT_INDEX%" (
            echo %%i^) ^(default^) !_JDK_NAME! [%%j]
        ) else (
            echo %%i^) !_JDK_NAME! [%%j]
        )
    )
)

if "%_JDK_INDEX%"=="" (
    set /P _JDK_INDEX="JDK-index> "
    if "!_JDK_INDEX!"=="" set _JDK_INDEX=%JDK_DEFAULT_INDEX%
)

:jdkname
set "_JDK_NAME=!JDK_NAMES[%_JDK_INDEX%]!"

if "%_JDK_NAME%"=="" (
    echo Invalid JDK index
    echo [Process stopped]: %0
    goto back
)

set "JAVA_HOME=!JDK_HOMES[%_JDK_INDEX%]!"
set "JAVA_JRE_HOME=!JRE_HOMES[%_JDK_INDEX%]!"

endlocal & set "JAVA_HOME=%JAVA_HOME%" & set "JAVA_JRE_HOME=%JAVA_JRE_HOME%"

echo Defined Environment Variables:
echo     JAVA_HOME=%JAVA_HOME%
echo     JAVA_JRE_HOME=%JAVA_JRE_HOME%
goto completed

:completed
echo:
echo [Completed]: %0
goto back


:back
cd /d %PWD%
