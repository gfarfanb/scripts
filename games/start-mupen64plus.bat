@echo OFF

rem ######################### Required variables
rem set MUPEN64PLUS_HOME=...
rem set N64_ROMS_HOME=...
rem set N64_SAVES_HOME=...
rem set N64_SCREENSHOTS_HOME=...
rem set GB_GBC_ROMS_HOME=...
rem set GB_GBC_SAVES_HOME=...

rem set "N64_JOYSTICK_NAMES[<joystick-index>]=<joystick-name>"
rem set "N64_JOYSTICK_CONFIGS[<joystick-index>]=<joystick-connection>"

rem set N64_CONFIGURED_JOYSTICK_LENGTH=<total-joystick-configs>
rem set N64_CONFIGURED_JOYSTICK_DEFAULT=<joystick-index-default>


rem ######################### Profile definition
rem set _pak_game_profiles[<game-hash>]=<pak-value>
rem set _gfx_game_profiles[<game-hash>]=<gfx-value>
rem set _emumode_game_profiles[<game-hash>]=<emumode-value>
rem set "_params_game_profiles[<game-hash>]=<params-value>"


rem ######################### Default values
set _controller_names[1]=Input-SDL-Control1
set _controller_names[2]=Input-SDL-Control2
set _controller_names[3]=Input-SDL-Control3
set _controller_names[4]=Input-SDL-Control4

set _controllers_default=1

rem 1=None
rem 2=Mem pak
rem 4=Transfer pak
rem 5=Rumble pak
set _expansion_pak_default=5

set _gfx_video_plugins[1]=mupen64plus-video-glide64mk2
set _gfx_video_plugins[2]=mupen64plus-video-rice
set _gfx_video_plugin_length=2
set _gfx_video_plugin_default=1

set _resolution_default=1024x768

set "_emulation_modes[0]=Pure Interpreter"
set "_emulation_modes[1]=Cached Interpreter"
set "_emulation_modes[2]=Dynamic Recompiler"
set _emulation_mode_default=2


setlocal enableDelayedExpansion


rem /********** N64 Roms menu **********/
set /a _n64_idx=1

for /f "delims=" %%N in ('dir %N64_ROMS_HOME%\*.n64 /b') do (
    set _n64_filenames[!_n64_idx!]=%%~N
    set /a _n64_idx+=1
)

set /a _loaded_n64_count=%_n64_idx%-1

for /L %%i in (1,1,%_loaded_n64_count%) do (
    echo [%%i] "!_n64_filenames[%%i]!"
)

set /P _n64_rom_idx="Choose a N64 game number: "
set "_n64_rom=!_n64_filenames[%_n64_rom_idx%]!"

if "%_n64_rom%" == "" goto noromfile
goto romselected


rem /********** N64 ROM selected **********/
:romselected

for /f "delims=" %%a in ('sha256sum "%_n64_rom%"') do @set _n64_rom_hash=%%a


rem /********** Number of controls menu **********/
echo:
set /P _controllers="Enter the number of controls [1-4] (default [%_controllers_default%]): "
if "%_controllers%"=="" set _controllers=%_controllers_default%


rem /********** Controllers setup **********/
set /a _controller_id=1
set "_expansion_pak_option_part="


rem ######################### [BEGIN] Controller setup
:controller

rem /********** Expansion pak menu **********/
echo:
set _pak_game_profile_expansion_pak=!_pak_game_profiles[%_n64_rom_hash%]!
if not "%_pak_game_profile_expansion_pak%"=="" set _expansion_pak_default=%_pak_game_profile_expansion_pak%

set /P _expansion_pak_idx="Choose the Expansion pak for Controller-%_controller_id% [1=None, 2=Mem pak, 4=Transfer pak, 5=Rumble pak] (default %_expansion_pak_default%): "
if "%_expansion_pak_idx%"=="" set _expansion_pak_idx=%_expansion_pak_default%
echo:

set _controller_name=!_controller_names[%_controller_id%]!


rem /********** Configured joysticks menu **********/
echo:

for /L %%l in (1,1,%N64_CONFIGURED_JOYSTICK_LENGTH%) do (
    echo [%%l] "!N64_JOYSTICK_NAMES[%%l]!"
)

set /P _configured_joystick_idx="Choose a configured joystick number for Controller-%_controller_id% (default %N64_CONFIGURED_JOYSTICK_DEFAULT%): "
if "%_configured_joystick_idx%"=="" set _configured_joystick_idx=%N64_CONFIGURED_JOYSTICK_DEFAULT%

set _n64_joystick_config=!N64_JOYSTICK_CONFIGS[%_configured_joystick_idx%]!

rem /********** Controller options **********/
set "_configuration_option_part=%_configuration_option_part% --set %_controller_name%[mode]=1"
set "_plugged_option_part=%_plugged_option_part% --set %_controller_name%[plugged]=True"

set "_joystick_option_part=%_joystick_option_part% --set %_controller_name%[name]=^"%_n64_joystick_config%^""
set _joystick_option_part=%_joystick_option_part:^^=%

set "_expansion_pak_option_part=%_expansion_pak_option_part% --set %_controller_name%[plugin]=%_expansion_pak_idx%"

if "%_expansion_pak_idx%"=="1" set "_expansion_pak_loaded=%_expansion_pak_loaded% Controller-%_controller_id%='None'"
if "%_expansion_pak_idx%"=="2" set "_expansion_pak_loaded=%_expansion_pak_loaded% Controller-%_controller_id%='Mem pak'"
if "%_expansion_pak_idx%"=="4" set "_expansion_pak_loaded=%_expansion_pak_loaded% Controller-%_controller_id%='Transfer pak'"
if "%_expansion_pak_idx%"=="5" set "_expansion_pak_loaded=%_expansion_pak_loaded% Controller-%_controller_id%='Rumble pak'"

if "%_expansion_pak_idx%"=="4" goto transferpak
set /a _controller_id+=1

if "%_controller_id%" gtr "%_controllers%" goto loading
goto controller

rem ######################### [END] Controller setup


rem ######################### [BEGIN] Transfer pak
:transferpak

set /a _gb_gbc_id=1

for /f "delims=" %%G in ('dir %GB_GBC_ROMS_HOME%\*.gb* /b') do (
    set gb_gbc_filename[!_gb_gbc_id!]=%%~G
    set /a _gb_gbc_id+=1
)

set /a _loaded_gb_gbc_count=%_gb_gbc_id%-1

for /L %%j in (1,1,%_loaded_gb_gbc_count%) do (
    echo [%%j] "!gb_gbc_filename[%%j]!"
)

set /P _gb_gbc_rom_idx="Choose a GB/GBC game number for Controller-%_controller_id%: "
set _gb_gbc_rom=!gb_gbc_filename[%_gb_gbc_rom_idx%]!

set "_transfer_pak_loaded=%_transfer_pak_loaded% Controller-%_controller_id%='%_gb_gbc_rom%'"

rem /********** Extracting GB/GBC game name **********/
for /F "tokens=1 delims=." %%F in ("%_gb_gbc_rom%") do set "_gb_gbc_name=%%F"

set "_transfer_pak_part=%_transfer_pak_part% --gb-rom-%_controller_id% ^"%GB_GBC_ROMS_HOME%\%_gb_gbc_rom%^" --gb-ram-%_controller_id% ^"%GB_GBC_SAVES_HOME%\%_gb_gbc_name%.sav^""
set _transfer_pak_part=%_transfer_pak_part:^^=%

set /a _controller_id+=1

if "%_controller_id%" gtr "%_controllers%" goto loading
goto controller

rem ######################### [END] Transfer pak


rem ######################### [BEGIN] Loading game
:loading


rem /********** Video plugin menu **********/
echo:
for /L %%k in (1,1,%_gfx_video_plugin_length%) do (
    echo [%%k] "!_gfx_video_plugins[%%k]!"
)

set _gfx_game_profile_video_plugin=!_gfx_game_profiles[%_n64_rom_hash%]!
if not "%_gfx_game_profile_video_plugin%"=="" set _gfx_video_plugin_default=%_gfx_game_profile_video_plugin%

set /P _gfx_video_plugin_idx="Choose a Video plugin number (default [%_gfx_video_plugin_default%]): "
if "%_gfx_video_plugin_idx%"=="" set _gfx_video_plugin_idx=%_gfx_video_plugin_default%

set _gfx_video_plugin=!_gfx_video_plugins[%_gfx_video_plugin_idx%]!


rem /********** Resolution menu **********/
echo:
set /P _resolution="Enter the display resolution [640x480, 800x600, 1024x768, etc.] (default [%_resolution_default%]): "
if "%_resolution%"=="" set _resolution=%_resolution_default%


rem /********** Emulation mode menu **********/
echo:
set _emumode_game_profile_emulation_mode=!_emumode_game_profiles[%_n64_rom_hash%]!
if not "%_emumode_game_profile_emulation_mode%"=="" set _emulation_mode_default=%_emumode_game_profile_emulation_mode%

set /P _emulation_mode_idx="Enter the emulation mode [0=Pure Interpreter 1=Cached Interpreter 2=Dynamic Recompiler] (default [%_emulation_mode_default%]): "
if "%_emulation_mode_idx%"=="" set _emulation_mode_idx=%_emulation_mode_default%

set _emulation_mode=!_emulation_modes[%_emulation_mode_idx%]!


rem /********** Merge all options **********/
set _params_game_profile_parameters=!_params_game_profiles[%_n64_rom_hash%]!
set "ALL_PARTS=%_params_game_profile_parameters% %_configuration_option_part% %_plugged_option_part% %_joystick_option_part% %_expansion_pak_option_part% %_transfer_pak_part%"


rem /********** Launching Mupen64Plus **********/
echo:
echo Loading game...
echo N64-Rom='%_n64_rom%'
echo N64-Rom-Hash='%_n64_rom_hash%'
echo Expansion-pak:%_expansion_pak_loaded%
echo Transfer-pak:%_transfer_pak_loaded%
echo Video-plugin='%_gfx_video_plugin%'
echo Resolution='%_resolution%'
echo Emulation-mode='%_emulation_mode%'
echo Parameters='%_params_game_profile_parameters%'

echo Additional-options=
set /a _arg_idx=1
set "_tab=    "
for %%A in (%*) do echo %_tab% %%!_arg_idx! %%A & set /a _arg_idx+=1
echo:

cd %MUPEN64PLUS_HOME%

rem [SOURCE] %MUPEN64PLUS_HOME%\README - UI Console Usage
mupen64plus-ui-console.exe %* --set Core[SaveSRAMPath]="%N64_SAVES_HOME%" --gfx %_gfx_video_plugin% --resolution %_resolution% --emumode %_emulation_mode_idx% --sshotdir "%N64_SCREENSHOTS_HOME%" %ALL_PARTS% "%N64_ROMS_HOME%\%_n64_rom%"

goto :eof

rem ######################### [END] Loading game

:noromfile
echo No ROM file selected
goto :eof

endlocal
