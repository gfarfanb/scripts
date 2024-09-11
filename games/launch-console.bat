@echo OFF

call env-vars.bat

goto main

:usage
echo Launches a game console.
echo ;
echo Usage: %0 [^<option^>]*
echo Option:
echo     -h: Displays this help message
goto back


:main
if /i "%1"=="-h" goto usage

echo Select a console:
echo 1^) Zelda 64: Recompiled
echo 2^) Perfect Dark port
echo 3^) 1964 GEPD Edition
echo 4^) GameCube/Wii
echo 5^) Nintendo 64
echo 6^) GBA/GBC/GB
echo 7^) SNES
set /P _console_index="console-index> "

if "%_console_index%"=="" (
    goto invalid
)

if /i "%_console_index%"=="1" goto launchzelda64
if /i "%_console_index%"=="2" goto launchperfectdark
if /i "%_console_index%"=="3" goto launch1964gepd
if /i "%_console_index%"=="4" goto launchdolphin
if /i "%_console_index%"=="5" goto launchmupen64plus
if /i "%_console_index%"=="6" goto launchmgba
if /i "%_console_index%"=="7" goto launchsnes9x
goto invalid


:launchzelda64
echo:
echo Launching 'Zelda 64: Recompiled' at "%ZELDA64RECOMPILED_HOME%"

call require-var ZELDA64RECOMPILED_HOME
call require-var ZELDA64RECOMPILED_SAVES_HOME
call require-var ZELDA64RECOMPILED_BACKUP_HOME

robocopy "%ZELDA64RECOMPILED_BACKUP_HOME%" "%ZELDA64RECOMPILED_SAVES_HOME%" /z
cd %ZELDA64RECOMPILED_HOME%
Zelda64Recompiled.exe
robocopy "%ZELDA64RECOMPILED_SAVES_HOME%" "%ZELDA64RECOMPILED_BACKUP_HOME%" /z
take-snapshot "%ZELDA64RECOMPILED_BACKUP_HOME%" bin
goto completed


:launchperfectdark
echo:
echo Launching 'perfect_dark' at "%PERFECTDARK_HOME%"

call require-var PERFECTDARK_HOME
call require-var PERFECTDARK_ROM
call require-var PERFECTDARK_SAVES_HOME
call require-var PERFECTDARK_BACKUP_HOME

robocopy "%PERFECTDARK_BACKUP_HOME%" "%PERFECTDARK_SAVES_HOME%" /z
cd %PERFECTDARK_HOME%
pd.exe --rom-file "%PERFECTDARK_ROM%"
robocopy "%PERFECTDARK_SAVES_HOME%" "%PERFECTDARK_BACKUP_HOME%" eeprom.bin /z
take-snapshot "%PERFECTDARK_BACKUP_HOME%" bin
goto completed


:launch1964gepd
echo:
echo Launching '1964 GEPD Edition' at "%GEPD_1964_HOME%"

call require-var GEPD_1964_HOME
call require-var GEPD_1964_SAVES_HOME
call require-var GEPD_1964_BACKUP_HOME

robocopy "%GEPD_1964_BACKUP_HOME%" "%GEPD_1964_SAVES_HOME%" /z
cd %GEPD_1964_HOME%
1964.exe
robocopy "%GEPD_1964_SAVES_HOME%" "%GEPD_1964_BACKUP_HOME%" /z
take-snapshot "%GEPD_1964_BACKUP_HOME%" eep
goto completed


:launchdolphin
echo:
echo Launching 'Dolphin' at "%DOLPHIN_HOME%"

call require-var DOLPHIN_HOME
call require-var DOLPHIN_BACKUP_HOME

cd %DOLPHIN_HOME%
Dolphin.exe
take-snapshot "%DOLPHIN_BACKUP_HOME%" gci
goto completed


:launchmupen64plus
echo:
echo Launching 'Mupen64Plus' at "%MUPEN64PLUS_HOME%"

call require-var MUPEN64PLUS_HOME
call require-var N64_ROMS_HOME
call require-var N64_SAVES_HOME
call require-var N64_SCREENSHOTS_HOME
call require-var GB_GBC_ROMS_HOME
call require-var GB_GBC_SAVES_HOME
call require-var N64_CONFIGURED_JOYSTICK_LENGTH
call require-var N64_CONFIGURED_JOYSTICK_DEFAULT

call n64-profiles.bat
call start-mupen64plus.bat %*
take-snapshot "%N64_SAVES_HOME%" eep mpk fla
goto completed


:launchmgba
echo:
echo Launching 'mGBA' at "%MGBA_HOME%"

call require-var MGBA_HOME
call require-var MGBA_BACKUP_HOME

cd %MGBA_HOME%
mGBA.exe
take-snapshot "%MGBA_BACKUP_HOME%" sav ss1
goto completed


:launchsnes9x
echo:
echo Launching 'Snes9x' at "%SNES9X_HOME%"

call require-var SNES9X_HOME
call require-var SNES9X_BACKUP_HOME

cd %SNES9X_HOME%
snes9x-x64.exe
take-snapshot "%SNES9X_BACKUP_HOME%" 000 0A.frz srm oops
goto completed


:invalid
echo Invalid console index
echo [Process invalid]
goto back


:completed
echo [Completed]
goto back

:back
cd %PWD%