@echo OFF
set PWD=%cd%

call env-vars.bat

goto main

:usage
echo Launches a game console.
echo ;
echo Usage: %0 [^<option^>]*
echo Option:
echo     -s: Saves snapshot without run the console
echo     -r: Recovers snapshot without run the console
echo     -b: Recovers backup without run the console
echo     -h: Displays this help message
goto back


:main
set /a _recover_backup=0
set /a _execute_console=1
set "_execute_recover="

if /i "%1"=="-b" (
    set /a _recover_backup=1
    set /a _execute_console=0
    goto select
)
if /i "%1"=="-r" (
    set "_execute_recover=-r"
    set /a _execute_console=0
    goto select
)
if /i "%1"=="-s" (
    set /a _execute_console=0
    goto select
)
if /i "%1"=="-h" goto usage

:select
echo Select a console:
echo 1^) Zelda 64: Recompiled
echo 2^) 1964 GEPD Edition
echo 3^) GameCube/Wii [Dolphin]
echo 4^) Nintendo 64 [Mupen64Plus]
echo 5^) GBA/GBC/GB [mGBA]
echo 6^) SNES [Snes9x]
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

if %_recover_backup% equ 1 (
    echo Getting 'Zelda 64: Recompiled' backup from "%ZELDA64RECOMPILED_BACKUP_HOME%"

    del /q "%ZELDA64RECOMPILED_SAVES_HOME%\*"
    robocopy "%ZELDA64RECOMPILED_BACKUP_HOME%" "%ZELDA64RECOMPILED_SAVES_HOME%" /z

    goto completed
)

if %_execute_console% equ 1 (
    echo Launching 'Zelda 64: Recompiled' at "%ZELDA64RECOMPILED_HOME%"

    cd %ZELDA64RECOMPILED_HOME%
    Zelda64Recompiled.exe

    robocopy "%ZELDA64RECOMPILED_SAVES_HOME%" "%ZELDA64RECOMPILED_BACKUP_HOME%" /z
)

call save-snapshot "%ZELDA64RECOMPILED_BACKUP_HOME%" %_execute_recover%

goto completed


:launch1964gepd
echo:

call require-var GEPD_1964_HOME
call require-var GEPD_1964_SAVES_HOME
call require-var GEPD_1964_BACKUP_HOME

if %_recover_backup% equ 1 (
    echo Getting '1964 GEPD Edition' backup from "%GEPD_1964_BACKUP_HOME%"

    del /q "%GEPD_1964_SAVES_HOME%\*"
    robocopy "%GEPD_1964_BACKUP_HOME%" "%GEPD_1964_SAVES_HOME%" /z

    goto completed
)

if %_execute_console% equ 1 (
    echo Launching '1964 GEPD Edition' at "%GEPD_1964_HOME%"

    cd %GEPD_1964_HOME%

    echo:
    echo Full screen mode press: 'Alt+Enter'
    echo Enable/disable mouse press: '4'

    1964.exe

    robocopy "%GEPD_1964_SAVES_HOME%" "%GEPD_1964_BACKUP_HOME%" /z
)

call save-snapshot "%GEPD_1964_BACKUP_HOME%" %_execute_recover%

goto completed


:launchdolphin
echo:

call require-var DOLPHIN_HOME
call require-var DOLPHIN_SAVES_HOME
call require-var DOLPHIN_BACKUP_HOME

if %_recover_backup% equ 1 (
    echo Getting 'Dolphin' backup from "%DOLPHIN_BACKUP_HOME%"

    del /q "%DOLPHIN_SAVES_HOME%\*"
    robocopy "%DOLPHIN_BACKUP_HOME%" "%DOLPHIN_SAVES_HOME%" /z

    goto completed
)

if %_execute_console% equ 1 (
    echo Launching 'Dolphin' at "%DOLPHIN_HOME%"

    cd %DOLPHIN_HOME%
    Dolphin.exe

    robocopy *.gci "%DOLPHIN_SAVES_HOME%" "%DOLPHIN_BACKUP_HOME%" /z
)

call save-snapshot "%DOLPHIN_BACKUP_HOME%" %_execute_recover%

goto completed


:launchmupen64plus
echo:

if %_recover_backup% equ 1 (
    echo Save files already synchronized for 'Mupen64Plus'

    goto completed
)

if %_execute_console% equ 1 (
    echo Launching 'Mupen64Plus' at "%MUPEN64PLUS_HOME%"

    call start-mupen64plus.bat %*
)

call save-snapshot "%N64_SAVES_HOME%" %_execute_recover%

goto completed


:launchmgba
echo:

call require-var MGBA_HOME
call require-var MGBA_BACKUP_HOME

if %_recover_backup% equ 1 (
    echo Save files already synchronized for 'mGBA'

    goto completed
)

if %_execute_console% equ 1 (
    echo Launching 'mGBA' at "%MGBA_HOME%"

    cd %MGBA_HOME%
    mGBA.exe
)

call save-snapshot "%MGBA_BACKUP_HOME%" %_execute_recover%

goto completed


:launchsnes9x
echo:

call require-var SNES9X_HOME
call require-var SNES9X_BACKUP_HOME

if %_recover_backup% equ 1 (
    echo Save files already synchronized for 'Snes9x'

    goto completed
)

if %_execute_console% equ 1 (
    echo Launching 'Snes9x' at "%SNES9X_HOME%"

    cd %SNES9X_HOME%
    snes9x-x64.exe
)

call save-snapshot "%SNES9X_BACKUP_HOME%" %_execute_recover%

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
