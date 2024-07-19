@echo OFF

rem ######################### Required variables
rem set MUPEN64PLUS_HOME=...
rem set N64_ROMS_HOME=...
rem set N64_SAVES_HOME=...
rem set N64_SCREENSHOTS_HOME=...
rem set GB_GBC_ROMS_HOME=...
rem set GB_GBC_SAVES_HOME=...


rem ######################### Profile definition
rem set pak_game_profile[<game-hash>]=<pak-value>
rem set gfx_game_profile[<game-hash>]=<gfx-value>
rem set emumode_game_profile[<game-hash>]=<emumode-value>
rem set "params_game_profile[<game-hash>]=<params-value>"


rem ######################### Controller definition
rem set "joystick_name[<controller-index>]=<controller-name>"
rem set "joystick_config[<controller-index>]=<controller-connection>"

rem set CONFIGURED_JOYSTICK_LENGTH=<total-controller-configs>
rem set CONFIGURED_JOYSTICK_DEFAULT=<controller-index-default>


rem ######################### Default values
set controller_name[1]=Input-SDL-Control1
set controller_name[2]=Input-SDL-Control2
set controller_name[3]=Input-SDL-Control3
set controller_name[4]=Input-SDL-Control4

IF "%CONFIGURED_JOYSTICK_LENGTH%"=="" set CONFIGURED_JOYSTICK_LENGTH=0
IF "%CONFIGURED_JOYSTICK_DEFAULT%"=="" set CONFIGURED_JOYSTICK_DEFAULT=1

set CONTROLLERS_DEFAULT=1

rem 1=None
rem 2=Mem pak
rem 4=Transfer pak
rem 5=Rumble pak
set EXPANSION_PAK_DEFAULT=5

set gfx_video_plugin[1]=mupen64plus-video-glide64mk2
set gfx_video_plugin[2]=mupen64plus-video-rice
set GFX_VIDEO_PLUGIN_LENGTH=2
set GFX_VIDEO_PLUGIN_DEFAULT=1

set RESOLUTION_DEFAULT=1024x768

set "emulation_mode[0]=Pure Interpreter"
set "emulation_mode[1]=Cached Interpreter"
set "emulation_mode[2]=Dynamic Recompiler"
set EMULATION_MODE_DEFAULT=2


setlocal enableDelayedExpansion


rem /********** N64 Roms menu **********/
set /a N64_ID=1

for /f "delims=" %%N in ('dir %N64_ROMS_HOME%\*.n64 /b') do (
    set n64_filename[!N64_ID!]=%%~N
    set /a N64_ID+=1
)

set /a LOADED_N64=%N64_ID%-1

for /L %%i in (1,1,%LOADED_N64%) do (
    echo [%%i] "!n64_filename[%%i]!"
)

set /P N64_ROM_IDX="Choose a N64 game number: "
set "N64_ROM=!n64_filename[%N64_ROM_IDX%]!"

if "%N64_ROM%" == "" goto noromfile
goto romselected


rem /********** N64 ROM selected **********/
:romselected

for /f "delims=" %%a in ('sha256sum "%N64_ROM%"') do @set N64_ROM_HASH=%%a


rem /********** Number of controls menu **********/
echo:
set /P CONTROLS="Enter the number of controls [1-4] (default [%CONTROLLERS_DEFAULT%]): "
if "%CONTROLS%"=="" set CONTROLS=%CONTROLLERS_DEFAULT%


rem /********** Controls setup **********/
set /a CONTROL_ID=1
set "EXPANSION_PAK_OPTION_PART="


rem ######################### [BEGIN] Control setup
:control

rem /********** Expansion pak menu **********/
echo:
set PAK_GAME_PROFILE_EXPANSION_PAK=!pak_game_profile[%N64_ROM_HASH%]!
if not "%PAK_GAME_PROFILE_EXPANSION_PAK%"=="" set EXPANSION_PAK_DEFAULT=%PAK_GAME_PROFILE_EXPANSION_PAK%

set /P EXPANSION_PAK_IDX="Choose the Expansion pak for Control-%CONTROL_ID% [1=None, 2=Mem pak, 4=Transfer pak, 5=Rumble pak] (default %EXPANSION_PAK_DEFAULT%): "
if "%EXPANSION_PAK_IDX%"=="" set EXPANSION_PAK_IDX=%EXPANSION_PAK_DEFAULT%
echo:

set CONTROLLER_NAME=!controller_name[%CONTROL_ID%]!


rem /********** Configured joysticks menu **********/
echo:

for /L %%l in (1,1,%CONFIGURED_JOYSTICK_LENGTH%) do (
    echo [%%l] "!joystick_name[%%l]!"
)

set /P CONFIGURED_JOYSTICK_IDX="Choose a configured joystick number for Control-%CONTROL_ID% (default %CONFIGURED_JOYSTICK_DEFAULT%): "
if "%CONFIGURED_JOYSTICK_IDX%"=="" set CONFIGURED_JOYSTICK_IDX=%CONFIGURED_JOYSTICK_DEFAULT%

set JOYSTICK_NAME=!joystick_config[%CONFIGURED_JOYSTICK_IDX%]!

rem /********** Controller options **********/
set "CONFIGURATION_OPTION_PART=%CONFIGURATION_OPTION_PART% --set %CONTROLLER_NAME%[mode]=1"
set "PLUGGED_OPTION_PART=%PLUGGED_OPTION_PART% --set %CONTROLLER_NAME%[plugged]=True"

set "JOYSTICK_OPTION_PART=%JOYSTICK_OPTION_PART% --set %CONTROLLER_NAME%[name]=^"%JOYSTICK_NAME%^""
set JOYSTICK_OPTION_PART=%JOYSTICK_OPTION_PART:^^=%

set "EXPANSION_PAK_OPTION_PART=%EXPANSION_PAK_OPTION_PART% --set %CONTROLLER_NAME%[plugin]=%EXPANSION_PAK_IDX%"

if "%EXPANSION_PAK_IDX%"=="1" set "EXPANSION_PAK_LOADED=%EXPANSION_PAK_LOADED% Control-%CONTROL_ID%='None'"
if "%EXPANSION_PAK_IDX%"=="2" set "EXPANSION_PAK_LOADED=%EXPANSION_PAK_LOADED% Control-%CONTROL_ID%='Mem pak'"
if "%EXPANSION_PAK_IDX%"=="4" set "EXPANSION_PAK_LOADED=%EXPANSION_PAK_LOADED% Control-%CONTROL_ID%='Transfer pak'"
if "%EXPANSION_PAK_IDX%"=="5" set "EXPANSION_PAK_LOADED=%EXPANSION_PAK_LOADED% Control-%CONTROL_ID%='Rumble pak'"

if "%EXPANSION_PAK_IDX%"=="4" goto transferpak
set /a CONTROL_ID+=1

if "%CONTROL_ID%" gtr "%CONTROLS%" goto loading
goto control

rem ######################### [END] Control setup


rem ######################### [BEGIN] Transfer pak
:transferpak

set /a GB_GBC_ID=1

for /f "delims=" %%G in ('dir %GB_GBC_ROMS_HOME%\*.gb* /b') do (
    set gb_gbc_filename[!GB_GBC_ID!]=%%~G
    set /a GB_GBC_ID+=1
)

set /a LOADED_GB_GBC=%GB_GBC_ID%-1

for /L %%j in (1,1,%LOADED_GB_GBC%) do (
    echo [%%j] "!gb_gbc_filename[%%j]!"
)

set /P GB_GBC_ROM_IDX="Choose a GB/GBC game number for Control-%CONTROL_ID%: "
set GB_GBC_ROM=!gb_gbc_filename[%GB_GBC_ROM_IDX%]!

set "TRANSFER_PAK_LOADED=%TRANSFER_PAK_LOADED% Control-%CONTROL_ID%='%GB_GBC_ROM%'"

rem /********** Extracting GB/GBC game name **********/
for /F "tokens=1 delims=." %%F in ("%GB_GBC_ROM%") do set "GB_GBC_NAME=%%F"

set "TRANSFER_PAK_PART=%TRANSFER_PAK_PART% --gb-rom-%CONTROL_ID% ^"%GB_GBC_ROMS_HOME%\%GB_GBC_ROM%^" --gb-ram-%CONTROL_ID% ^"%GB_GBC_SAVES_HOME%\%GB_GBC_NAME%.sav^""
set TRANSFER_PAK_PART=%TRANSFER_PAK_PART:^^=%

set /a CONTROL_ID+=1

if "%CONTROL_ID%" gtr "%CONTROLS%" goto loading
goto control

rem ######################### [END] Transfer pak


rem ######################### [BEGIN] Loading game
:loading


rem /********** Video plugin menu **********/
echo:
for /L %%k in (1,1,%GFX_VIDEO_PLUGIN_LENGTH%) do (
    echo [%%k] "!gfx_video_plugin[%%k]!"
)

set GFX_GAME_PROFILE_VIDEO_PLUGIN=!gfx_game_profile[%N64_ROM_HASH%]!
if not "%GFX_GAME_PROFILE_VIDEO_PLUGIN%"=="" set GFX_VIDEO_PLUGIN_DEFAULT=%GFX_GAME_PROFILE_VIDEO_PLUGIN%

set /P GFX_VIDEO_PLUGIN_IDX="Choose a Video plugin number (default [%GFX_VIDEO_PLUGIN_DEFAULT%]): "
if "%GFX_VIDEO_PLUGIN_IDX%"=="" set GFX_VIDEO_PLUGIN_IDX=%GFX_VIDEO_PLUGIN_DEFAULT%

set GFX_VIDEO_PLUGIN=!gfx_video_plugin[%GFX_VIDEO_PLUGIN_IDX%]!


rem /********** Resolution menu **********/
echo:
set /P RESOLUTION="Enter the display resolution [640x480, 800x600, 1024x768, etc.] (default [%RESOLUTION_DEFAULT%]): "
if "%RESOLUTION%"=="" set RESOLUTION=%RESOLUTION_DEFAULT%


rem /********** Emulation mode menu **********/
echo:
set EMUMODE_GAME_PROFILE_EMULATION_MODE=!emumode_game_profile[%N64_ROM_HASH%]!
if not "%EMUMODE_GAME_PROFILE_EMULATION_MODE%"=="" set EMULATION_MODE_DEFAULT=%EMUMODE_GAME_PROFILE_EMULATION_MODE%

set /P EMULATION_MODE_IDX="Enter the emulation mode [0=Pure Interpreter 1=Cached Interpreter 2=Dynamic Recompiler] (default [%EMULATION_MODE_DEFAULT%]): "
if "%EMULATION_MODE_IDX%"=="" set EMULATION_MODE_IDX=%EMULATION_MODE_DEFAULT%

set EMULATION_MODE=!emulation_mode[%EMULATION_MODE_IDX%]!


rem /********** Merge all options **********/
set PARAMS_GAME_PROFILE_PARAMETERS=!params_game_profile[%N64_ROM_HASH%]!
set "ALL_PARTS=%PARAMS_GAME_PROFILE_PARAMETERS% %CONFIGURATION_OPTION_PART% %PLUGGED_OPTION_PART% %JOYSTICK_OPTION_PART% %EXPANSION_PAK_OPTION_PART% %TRANSFER_PAK_PART%"


rem /********** Launching Mupen64Plus **********/
echo:
echo Loading game...
echo N64-Rom='%N64_ROM%'
echo N64-Rom-Hash='%N64_ROM_HASH%'
echo Expansion-pak:%EXPANSION_PAK_LOADED%
echo Transfer-pak:%TRANSFER_PAK_LOADED%
echo Video-plugin='%GFX_VIDEO_PLUGIN%'
echo Resolution='%RESOLUTION%'
echo Emulation-mode='%EMULATION_MODE%'
echo Parameters='%PARAMS_GAME_PROFILE_PARAMETERS%'

echo Additional-options=
set /a ARG_IDX=1
set "TAB=    "
for %%A in (%*) do echo %TAB% %%!ARG_IDX! %%A & set /a ARG_IDX+=1
echo:

cd %MUPEN64PLUS_HOME%

rem [SOURCE] %MUPEN64PLUS_HOME%\README - UI Console Usage
mupen64plus-ui-console.exe %* --set Core[SaveSRAMPath]="%N64_SAVES_HOME%" --gfx %GFX_VIDEO_PLUGIN% --resolution %RESOLUTION% --emumode %EMULATION_MODE_IDX% --sshotdir "%N64_SCREENSHOTS_HOME%" %ALL_PARTS% "%N64_ROMS_HOME%\%N64_ROM%"

goto :eof

rem ######################### [END] Loading game

:noromfile
echo No ROM file selected
goto :eof

endlocal
