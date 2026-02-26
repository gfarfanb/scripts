@echo OFF
set PWD=%cd%

call env-vars.bat
call require-var JDK_CERT_BACKUP_HOME
call require-var JDK_PEM_HOME

goto main

:usage
echo Generates a CERT based on a PEM file and imports it
echo:
echo Usage: %0 [^<jdk_version^>^|^<option^>]*
echo Option:
echo     -i: Imports a CERT from backup
echo     -h: Displays this help message
goto back

:main
if /i "%~1"=="-h" goto usage
if /i "%~1"=="-i" goto import

setlocal enableDelayedExpansion

call setup-jdk %*

if exist "%PEM_FILE_HOME%\*.pem" goto loadcerts
goto certnotfound

:loadcerts
set /a PEM_ID=1

for /f "delims=" %%N in ('dir "%PEM_FILE_HOME%\*.pem" /b') do (
    set pem_filename[!PEM_ID!]=%%~N
    set /a PEM_ID+=1
)

set /a LOADED_PEMS=%PEM_ID%-1

for /L %%i in (1,1,%LOADED_PEMS%) do (
    echo [%%i] "!pem_filename[%%i]!"
)

set "PEM_IDX="
set /P PEM_IDX="Choose a PEM file (default [1]): "
if "%PEM_IDX%"=="" set PEM_IDX=1

set PEM_FILE=!pem_filename[%PEM_IDX%]!

for %%a in (%PEM_FILE%) do (
    set PEM_FILENAME=%%~na
)

cd %JDK_CERT_BACKUP_HOME%

set CERT_ALIAS=cert-%PEM_FILENAME%

del %PEM_FILENAME%.pem
del %PEM_FILENAME%.cert
cp "%PEM_FILE_HOME%\%PEM_FILE%" .

openssl x509 -outform der -in %PEM_FILENAME%.pem -out %PEM_FILENAME%.cert

cd %JAVA_HOME%\bin

set "DELETE_CMD=keytool -delete -noprompt -trustcacerts -alias ^"%CERT_ALIAS%^" -keystore ^"%JAVA_JRE_HOME%\lib\security\cacerts^""

echo:
echo %DELETE_CMD%
%DELETE_CMD%

set "IMPORT_CMD=keytool -import -alias %CERT_ALIAS% -file ^"%PEM_FILENAME%.cert^" -keystore ^"%JAVA_JRE_HOME%\lib\security\cacerts^" -storepass changeit"

echo:
echo %IMPORT_CMD%
%IMPORT_CMD%

cd "%PEM_FILE_HOME%"
del %PEM_FILE%
goto completed


:import
call setup-jdk

set /a CERT_ID=1

for /f "delims=" %%N in ('dir "%JDK_CERT_BACKUP_HOME%\*.cert" /b') do (
    set cert_filename[!CERT_ID!]=%%~N
    set /a CERT_ID+=1
)

set /a LOADED_CERTS=%CERT_ID%-1

for /L %%i in (1,1,%LOADED_CERTS%) do (
    echo [%%i] "!cert_filename[%%i]!"
)

set "CERT_IDX="
set /P CERT_IDX="Choose a CERT file (default [1]): "
if "%CERT_IDX%"=="" set CERT_IDX=1

set CERT_FILE=!cert_filename[%CERT_IDX%]!

for %%a in (%CERT_FILE%) do (
    set CERT_FILENAME=%%~na
)

cd %JDK_CERT_BACKUP_HOME%

set CERT_ALIAS=cert-%CERT_FILENAME%

cd %JAVA_HOME%\bin

set "IMPORT_CMD=keytool -import -alias %CERT_ALIAS% -file ^"%CERT_FILENAME%.cert^" -keystore ^"%JAVA_JRE_HOME%\lib\security\cacerts^" -storepass changeit"

echo:
echo %IMPORT_CMD%
%IMPORT_CMD%
goto completed

endlocal


:certnotfound
echo PEM files not found
echo [Process invalid]: %0
goto back


:completed
echo:
echo [Completed]: %0
goto back


:back
cd /d %PWD%
