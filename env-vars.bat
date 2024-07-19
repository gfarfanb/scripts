@echo OFF

set PWD=%cd%

set "EMACS_HOME="


rem ######################### Snapshots
set /a SNAPSHOTS_TO_KEEP=10


rem ######################### Set 'Zelda 64: Recompiled' variables
set ZELDA64RECOMPILED_HOME=C:\Dist\Zelda64Recompiled\Zelda64Recompiled-v1.1.1-Windows
set ZELDA64RECOMPILED_SAVES_HOME=C:\Users\giova\AppData\Local\Zelda64Recompiled\saves
set ZELDA64RECOMPILED_BACKUP_HOME=D:\cloud\OneDrive\Games\Saves\N64\Zelda64Recompiled


rem ######################### Set 'perfect_dark' variables
set PERFECTDARK_HOME=C:\Dist\perfect_dark\pd-i686-windows
set "PERFECTDARK_ROM=D:\media\roms\N64\ntsc\Perfect Dark.z64"
set PERFECTDARK_SAVES_HOME=C:\Dist\perfect_dark\pd-i686-windows
set PERFECTDARK_BACKUP_HOME=D:\cloud\OneDrive\Games\Saves\N64\perfect_dark


rem ######################### Set '1964 GEPD Edition' variables
set GEPD_1964_HOME=C:\Dist\1964GEPD\1964-0.8.5
set GEPD_1964_SAVES_HOME=C:\Dist\1964GEPD\1964-0.8.5\save
set GEPD_1964_BACKUP_HOME=D:\cloud\OneDrive\Games\Saves\N64\1964GEPD


rem ######################### Set 'Dolphin' variables
set DOLPHIN_HOME=C:\Dist\Dolphin\dolphin-2407\Dolphin-x64
set DOLPHIN_BACKUP_HOME=D:\cloud\OneDrive\Games\Saves\GameCube\GCI\USA


rem ######################### Set 'Mupen64Plus' (Start-Mupen64Plus.bat) variables
set MUPEN64PLUS_HOME=C:\Dist\Mupen64Plus\mupen64plus-bundle-win64-2.6.0\Release
set N64_ROMS_HOME=D:\media\roms\N64
set N64_SAVES_HOME=D:\cloud\OneDrive\Games\Saves\N64\Mupen64Plus
set N64_SCREENSHOTS_HOME=D:\cloud\Dropbox\Games\Screenshots
set N64_CONTROLLER_PROFILES_HOME=D:\cloud\OneDrive\Games\Profiles\Mupen64Plus
set GB_GBC_ROMS_HOME=D:\media\roms\GB+GBC
set GB_GBC_SAVES_HOME=D:\cloud\OneDrive\Games\Saves\GB+GBC+GBA


rem ######################### Set 'mGBA' variables
set MGBA_HOME=C:\Dist\mGBA\mGBA-0.10.3-win64
set MGBA_BACKUP_HOME=D:\cloud\OneDrive\Games\Saves\GB+GBC+GBA


rem ######################### Set 'Snes9x' variables
set SNES9X_HOME=C:\Dist\Snes9x\snes9x-1.63-win32-x64
set SNES9X_BACKUP_HOME=D:\cloud\OneDrive\Games\Saves\SNES
