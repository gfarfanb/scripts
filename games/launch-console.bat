@echo OFF
set PWD=%cd%

call env-vars.bat

goto main

:usage
echo Launches a game console.
echo ;
echo Usage: %0 [^<option^>]*
echo Option:
echo     -s: Goes to save snapshot without run the console
echo     -h: Displays this help message
goto back


:main
set /a _execute_console=1
if /i "%1"=="-s" (
    set /a _execute_console=0
    goto select
)
if /i "%1"=="-h" goto usage

:select
echo Select a console:
echo 1^) Zelda 64: Recompiled
echo 2^) 1964 GEPD Edition
echo 3^) GameCube/Wii
echo 4^) Nintendo 64
echo 5^) GBA/GBC/GB
echo 6^) SNES
set "_console_index="
set /P _console_index="console-index> "

if "%_console_index%"=="" (
    goto invalid
)

if /i "%_console_index%"=="1" goto launchzelda64
if /i "%_console_index%"=="2" goto launch1964gepd
if /i "%_console_index%"=="3" goto launchdolphin
if /i "%_console_index%"=="4" goto launchmupen64plus
if /i "%_console_index%"=="5" goto launchmgba
if /i "%_console_index%"=="6" goto launchsnes9x
goto invalid


:launchzelda64
echo:

call require-var ZELDA64RECOMPILED_HOME
call require-var ZELDA64RECOMPILED_SAVES_HOME
call require-var ZELDA64RECOMPILED_BACKUP_HOME

if %_execute_console% equ 1 (
    echo Launching 'Zelda 64: Recompiled' at "%ZELDA64RECOMPILED_HOME%"

    robocopy "%ZELDA64RECOMPILED_BACKUP_HOME%" "%ZELDA64RECOMPILED_SAVES_HOME%" /z
    cd %ZELDA64RECOMPILED_HOME%
    Zelda64Recompiled.exe
    robocopy "%ZELDA64RECOMPILED_SAVES_HOME%" "%ZELDA64RECOMPILED_BACKUP_HOME%" /z
)

call save-snapshot "%ZELDA64RECOMPILED_BACKUP_HOME%"
goto completed


:launch1964gepd
echo:

call require-var GEPD_1964_HOME
call require-var GEPD_1964_SAVES_HOME
call require-var GEPD_1964_BACKUP_HOME

if %_execute_console% equ 1 (
    echo Launching '1964 GEPD Edition' at "%GEPD_1964_HOME%"

    robocopy "%GEPD_1964_BACKUP_HOME%" "%GEPD_1964_SAVES_HOME%" /z
    cd %GEPD_1964_HOME%
    1964.exe
    robocopy "%GEPD_1964_SAVES_HOME%" "%GEPD_1964_BACKUP_HOME%" /z
)

call save-snapshot "%GEPD_1964_BACKUP_HOME%"
goto completed


:launchdolphin
echo:

call require-var DOLPHIN_HOME
call require-var DOLPHIN_SAVES_HOME
call require-var DOLPHIN_BACKUP_HOME

if %_execute_console% equ 1 (
    echo Launching 'Dolphin' at "%DOLPHIN_HOME%"

    robocopy "%DOLPHIN_BACKUP_HOME%" "%DOLPHIN_SAVES_HOME%" /z
    cd %DOLPHIN_HOME%
    Dolphin.exe
    robocopy "%DOLPHIN_SAVES_HOME%" "%DOLPHIN_BACKUP_HOME%" /z
)

call save-snapshot "%DOLPHIN_BACKUP_HOME%"
goto completed


:launchmupen64plus
echo:

if %_execute_console% equ 1 (
    echo Launching 'Mupen64Plus' at "%MUPEN64PLUS_HOME%"

    call n64-profiles.bat
    call start-mupen64plus.bat %*
)

call save-snapshot "%N64_SAVES_HOME%"
goto completed


:launchmgba
echo:

call require-var MGBA_HOME
call require-var MGBA_BACKUP_HOME

if %_execute_console% equ 1 (
    echo Launching 'mGBA' at "%MGBA_HOME%"

    cd %MGBA_HOME%
    mGBA.exe
)

call save-snapshot "%MGBA_BACKUP_HOME%"
goto completed


:launchsnes9x
echo:

call require-var SNES9X_HOME
call require-var SNES9X_BACKUP_HOME

if %_execute_console% equ 1 (
    echo Launching 'Snes9x' at "%SNES9X_HOME%"

    cd %SNES9X_HOME%
    snes9x-x64.exe
)

call save-snapshot "%SNES9X_BACKUP_HOME%"
goto completed


:invalid
echo Invalid console index
echo [Process invalid]: %0
goto back


:completed
echo [Completed]: %0
goto back

:back
cd /d %PWD%
