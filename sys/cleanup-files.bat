@echo OFF
set "PWD=%cd%" && for %%F in (%0) do set BASEDIR=%%~dpF
cd %BASEDIR%

call ..\env-vars

goto :main

rem Based on https://github.com/Leedeo/Leedeo-Cleaner/blob/main/MainWindow.cs

:__usage_page
echo Cleanup common Windows temporary/cached files and registry.
echo:
for %%F in (%0) do set BASENAME=%%~nF
echo Usage: %BASENAME% [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto :back

:main
if /i "%~1"=="-h" goto :__usage_page

del /s /q "%TEMP%\*" >nul 2>&1
echo User temporary files cleaned

del /s /q C:\Windows\Temp\* >nul 2>&1
echo System temporary files cleaned

ipconfig /flushdns >nul 2>&1
echo DNS cache flushed

net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
echo Windows Update services stopped

del /s /q C:\Windows\SoftwareDistribution\Download\* >nul 2>&1
echo Windows Update cache cleaned

net start wuauserv >nul 2>&1
echo Windows Update service restarted

for /f "tokens=*" %%i in ('wevtutil el') do @wevtutil cl "%%i" >nul 2>&1
echo Event logs cleared

del /s /q "C:\ProgramData\Microsoft\Windows Defender\Scans\History\*" >nul 2>&1
echo Defender scan history cleaned

del /s /q C:\Windows\Prefetch\* >nul 2>&1
echo Prefetch files cleaned

powershell -Command "Start-Process powershell -ArgumentList '-Command dotnet run $env:SCRIPTS_HOME\sys\.cs\RegistryCleaner.cs' -Verb RunAs"

goto :completed


:completed
echo:
echo [Completed]: %0
goto :back


:back
cd /d %PWD%
