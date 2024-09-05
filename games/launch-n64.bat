@echo OFF

call env-vars.bat
call require-var MUPEN64PLUS_HOME
call require-var N64_ROMS_HOME
call require-var N64_SAVES_HOME
call require-var N64_SCREENSHOTS_HOME
call require-var GB_GBC_ROMS_HOME
call require-var GB_GBC_SAVES_HOME
call require-var N64_CONFIGURED_JOYSTICK_LENGTH
call require-var N64_CONFIGURED_JOYSTICK_DEFAULT

call n64-profiles.bat

echo Launching 'Mupen64Plus' at "%MUPEN64PLUS_HOME%"
call start-mupen64plus.bat %*

take-snapshot "%N64_SAVES_HOME%" eep mpk fla
