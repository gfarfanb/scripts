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

set "_expansion_paks[1]=1|None"
set "_expansion_paks[2]=2|Mem pak"
set "_expansion_paks[3]=4|Transfer pak"
set "_expansion_paks[4]=5|Rumble pak"
set _expansion_paks_length=4
set "_expansion_pak_default=Rumble pak"

set _gfx_video_plugins[1]=mupen64plus-video-glide64mk2
set _gfx_video_plugins[2]=mupen64plus-video-rice
set _gfx_video_plugin_length=2
set _gfx_video_plugin_default=mupen64plus-video-glide64mk2

set _resolution_default=1024x768

set "_emulation_modes[1]=0|Pure Interpreter"
set "_emulation_modes[2]=1|Cached Interpreter"
set "_emulation_modes[3]=2|Dynamic Recompiler"
set _emulation_modes_length=3
set "_emulation_mode_default=Dynamic Recompiler"


setlocal enableDelayedExpansion


rem /********** N64 Roms menu **********/
set /a _n64_idx=1

for /f "delims=" %%N in ('dir %N64_ROMS_HOME%\*.n64 /b') do (
    set _n64_filenames[!_n64_idx!]=%%~N
    set /a _n64_idx+=1
)

set /a _loaded_n64_count=%_n64_idx%-1

echo:
echo Choose an N64 game:
for /L %%i in (1,1,%_loaded_n64_count%) do (
    echo %%i^) !_n64_filenames[%%i]!
)

set /P _n64_rom_idx="n64-index> "
set "_n64_rom=!_n64_filenames[%_n64_rom_idx%]!"

if "%_n64_rom%"=="" goto noromfile
goto romselected


rem /********** N64 ROM selected **********/
:romselected

for /f "delims=" %%a in ('sha256sum "%_n64_rom%"') do @set _n64_rom_hash=%%a


rem /********** Number of controls menu **********/
echo:
echo Enter the number of controls [1-4] (default [%_controllers_default%]):
set /P _controllers="num-controllers> "
if "%_controllers%"=="" set _controllers=%_controllers_default%


rem /********** Controllers setup **********/
set /a _controller_id=1
set "_expansion_pak_option_part="


rem ######################### [BEGIN] Controller setup
:controller

rem /********** Expansion pak menu **********/
set _pak_game_profile_expansion_pak=!_pak_game_profiles[%_n64_rom_hash%]!
if not "%_pak_game_profile_expansion_pak%"=="" set _expansion_pak_default=%_pak_game_profile_expansion_pak%

echo:
echo Choose the Expansion pak for Controller-%_controller_id%:
for /L %%i in (1,1,%_expansion_paks_length%) do (
    for /F "tokens=2 delims=|" %%j in ("!_expansion_paks[%%i]!") do (
        if "%_expansion_pak_default%"=="%%j" (
            echo %%i^) ^(default^) %%j
        ) else (
            echo %%i^) %%j
        )
    )
)

set /P _expansion_pak_idx="expansion-pak-num> "

if "%_expansion_pak_idx%"=="" (
    for /L %%i in (1,1,%_expansion_paks_length%) do (
        for /F "tokens=1,2 delims=|" %%j in ("!_expansion_paks[%%i]!") do (
            if "%_expansion_pak_default%"=="%%k" (
                set _expansion_pak_idx=%%j
                set "_expansion_pak_loaded=%_expansion_pak_loaded% Controller-%_controller_id%='%%k'"
            )
        )
    )
) else (
    for /F "tokens=1,2 delims=|" %%i in ("!_expansion_paks[%_expansion_pak_idx%]!") do (
        set _expansion_pak_idx=%%i
        set "_expansion_pak_loaded=%_expansion_pak_loaded% Controller-%_controller_id%='%%j'"
    )
)

set _controller_name=!_controller_names[%_controller_id%]!


rem /********** Configured joysticks menu **********/
echo:
echo Choose a configured joystick number for Controller-%_controller_id%:
for /L %%l in (1,1,%N64_CONFIGURED_JOYSTICK_LENGTH%) do (
    if "%N64_CONFIGURED_JOYSTICK_DEFAULT%"=="%%l" (
        echo %%l^) ^(default^) !N64_JOYSTICK_NAMES[%%l]!
    ) else (
        echo %%l^) !N64_JOYSTICK_NAMES[%%l]!
    )
)

set /P _configured_joystick_idx="joystick-config-index> "
if "%_configured_joystick_idx%"=="" set _configured_joystick_idx=%N64_CONFIGURED_JOYSTICK_DEFAULT%

set _n64_joystick_config=!N64_JOYSTICK_CONFIGS[%_configured_joystick_idx%]!

rem /********** Controller options **********/
set "_configuration_option_part=%_configuration_option_part% --set %_controller_name%[mode]=1"
set "_plugged_option_part=%_plugged_option_part% --set %_controller_name%[plugged]=True"

set "_joystick_option_part=%_joystick_option_part% --set %_controller_name%[name]=^"%_n64_joystick_config%^""
set _joystick_option_part=%_joystick_option_part:^^=%

set "_expansion_pak_option_part=%_expansion_pak_option_part% --set %_controller_name%[plugin]=%_expansion_pak_idx%"

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

echo:
echo Choose a GB/GBC game number for Controller-%_controller_id%:
for /L %%j in (1,1,%_loaded_gb_gbc_count%) do (
    echo %%j^) !gb_gbc_filename[%%j]!
)

set /P _gb_gbc_rom_idx="gc-gbc-index> "
set _gb_gbc_rom=!gb_gbc_filename[%_gb_gbc_rom_idx%]!

set "_transfer_pak_loaded=%_transfer_pak_loaded% Controller-%_controller_id%='%_gb_gbc_rom%'"

rem /********** Extracting GB/GBC game name **********/
for /F "tokens=1 delims=." %%F in ("%_gb_gbc_rom%") do set "_gb_gbc_name=%%F"

set "_transfer_pak_option_part=%_transfer_pak_option_part% --gb-rom-%_controller_id% ^"%GB_GBC_ROMS_HOME%\%_gb_gbc_rom%^" --gb-ram-%_controller_id% ^"%GB_GBC_SAVES_HOME%\%_gb_gbc_name%.sav^""
set _transfer_pak_option_part=%_transfer_pak_option_part:^^=%

set /a _controller_id+=1

if "%_controller_id%" gtr "%_controllers%" goto loading
goto controller

rem ######################### [END] Transfer pak


rem ######################### [BEGIN] Loading game
:loading


rem /********** Video plugin menu **********/
set _gfx_game_profile_video_plugin=!_gfx_game_profiles[%_n64_rom_hash%]!
if not "%_gfx_game_profile_video_plugin%"=="" set _gfx_video_plugin_default=%_gfx_game_profile_video_plugin%

echo:
echo Choose a Video plugin number:
for /L %%k in (1,1,%_gfx_video_plugin_length%) do (
    if "!_gfx_video_plugin_default!"=="!_gfx_video_plugins[%%k]!" (
        echo %%k^) ^(default^) !_gfx_video_plugins[%%k]!
    ) else (
        echo %%k^) !_gfx_video_plugins[%%k]!
    )
)

set /P _gfx_video_plugin_idx="gfx-video-index> "
if "%_gfx_video_plugin_idx%"=="" (
    set _gfx_video_plugin=%_gfx_video_plugin_default%
) else (
    set _gfx_video_plugin=!_gfx_video_plugins[%_gfx_video_plugin_idx%]!
)


rem /********** Resolution menu **********/
echo:
echo Enter the display resolution [640x480, 800x600, etc.] (default [%_resolution_default%]):
set /P _resolution="resolution> "
if "%_resolution%"=="" set _resolution=%_resolution_default%


rem /********** Emulation mode menu **********/
set _emumode_game_profile_emulation_mode=!_emumode_game_profiles[%_n64_rom_hash%]!
if not "%_emumode_game_profile_emulation_mode%"=="" set _emulation_mode_default=%_emumode_game_profile_emulation_mode%

echo:
echo Choose the emulation mode:
for /L %%i in (1,1,%_emulation_modes_length%) do (
    for /F "tokens=2 delims=|" %%j in ("!_emulation_modes[%%i]!") do (
        if "%_emulation_mode_default%"=="%%j" (
            echo %%i^) ^(default^) %%j
        ) else (
            echo %%i^) %%j
        )
    )
)

set /P _emumode_idx="emumode-index> "

if "%_emumode_idx%"=="" (
    for /L %%i in (1,1,%_emulation_modes_length%) do (
        for /F "tokens=1,2 delims=|" %%j in ("!_emulation_modes[%%i]!") do (
            if "%_emulation_mode_default%"=="%%k" (
                set _emulation_mode_idx=%%j
                set _emulation_mode=%%k
            )
        )
    )
) else (
    for /F "tokens=1,2 delims=|" %%i in ("!_emulation_modes[%_emumode_idx%]!") do (
        set _emulation_mode_idx=%%i
        set _emulation_mode=%%j
    )
)


rem /********** Merge all options **********/
set _params_game_profile_parameters=!_params_game_profiles[%_n64_rom_hash%]!
set "_all_parts=%_params_game_profile_parameters% %_configuration_option_part% %_plugged_option_part% %_joystick_option_part% %_expansion_pak_option_part% %_transfer_pak_option_part%"


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
echo mupen64plus-ui-console.exe %* --set Core[SaveSRAMPath]="%N64_SAVES_HOME%" --gfx %_gfx_video_plugin% --resolution %_resolution% --emumode %_emulation_mode_idx% --sshotdir "%N64_SCREENSHOTS_HOME%" %_all_parts% "%N64_ROMS_HOME%\%_n64_rom%"

goto :eof

rem ######################### [END] Loading game

:noromfile
echo No ROM file selected
goto :eof

endlocal
