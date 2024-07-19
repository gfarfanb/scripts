@echo OFF

rem [SOURCE] Core Parameters: https://mupen64plus.org/wiki/index.php?title=Mupen64Plus_Core_Parameters
rem [SOURCE] Plugin Parameters: https://mupen64plus.org/wiki/index.php?title=Mupen64Plus_Plugin_Parameters

rem /********** Banjo-Kazooie **********/
rem [Mupen64Plus Options]
rem Pak=Rumble pak
rem GFX=mupen64plus-video-rice
rem enumode=Dynamic Recompiler
for /f "delims=" %%a in ('sha256sum "Banjo-Kazooie.n64"') do (
    set "pak_game_profile[%%a]="
    set gfx_game_profile[%%a]=2
    set emumode_game_profile[%%a]=2
    set "params_game_profile[%%a]="
)

rem [Saves]
for /f "delims=" %%a in ('sha256sum "Banjo-Kazooie (U) (V1.1) [].eep"') do (
    set "profile_save_file[%%a]=Banjo-Kazooie (U) (V1.1) [!].eep"
)
for /f "delims=" %%a in ('sha256sum "Banjo-Kazooie (U) (V1.1) [].mpk"') do (
    set "profile_save_file[%%a]=Banjo-Kazooie (U) (V1.1) [!].mpk"
)


rem /********** Banjo-Tooie **********/
rem [Mupen64Plus Options]
rem Pak=Rumble pak
rem GFX=mupen64plus-video-rice
rem enumode=Pure Interpreter
for /f "delims=" %%a in ('sha256sum "Banjo-Tooie.n64"') do (
    set "pak_game_profile[%%a]="
    set gfx_game_profile[%%a]=2
    set emumode_game_profile[%%a]=0
    set "params_game_profile[%%a]="
)

rem [Saves]
for /f "delims=" %%a in ('sha256sum "Banjo-Tooie (U) [].eep"') do (
    set "profile_save_file[%%a]=Banjo-Tooie (U) [!].eep"
)
for /f "delims=" %%a in ('sha256sum "Banjo-Tooie (U) [].mpk"') do (
    set "profile_save_file[%%a]=Banjo-Tooie (U) [!].mpk"
)


rem /********** Pokemon Stadium **********/
rem [Mupen64Plus Options]
rem Pak=Transfer pak
rem GFX=mupen64plus-video-glide64mk2
rem enumode=Dynamic Recompiler
for /f "delims=" %%a in ('sha256sum "Pokemon Stadium.n64"') do (
    set pak_game_profile[%%a]=4
    set "gfx_game_profile[%%a]="
    set "emumode_game_profile[%%a]="
    set "params_game_profile[%%a]="
)

rem [Saves]
for /f "delims=" %%a in ('sha256sum "Pokemon Stadium (U) (V1.0) [].fla"') do (
    set "profile_save_file[%%a]=Pokemon Stadium (U) (V1.0) [!].fla"
)
