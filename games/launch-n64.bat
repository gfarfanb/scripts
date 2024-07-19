@echo OFF

call env-vars.bat
call n64-profiles.bat

rem /********** Controllers **********/
echo Controller configuration must be in [%MUPEN64PLUS_HOME%\InputAutoCfg.ini]
echo Setup for '8BitDo SN30 Pro' [%N64_CONTROLLER_PROFILES_HOME%\8BitDo SN30 Pro.iacfg]
echo Setup for 'Keyboard' [%N64_CONTROLLER_PROFILES_HOME%\Keyboard.iacfg]
echo:

set "joystick_name[1]=8BitDo SN30 Pro"
set "joystick_name[2]=Keyboard"
rem set "joystick_name[3]=XBox Wireless Controller Series X|S"
rem set "joystick_name[4]=8BitDo USB Wireless Adapter 2"

set "joystick_config[1]=Bluetooth XINPUT compatible input device"
set "joystick_config[2]=Keyboard"
rem set "joystick_config[3]=Xbox Bluetooth LE XINPUT compatible input device"
rem set "joystick_config[4]=8BitDo Receiver"

set CONFIGURED_JOYSTICK_LENGTH=2
set CONFIGURED_JOYSTICK_DEFAULT=1

rem /********** Launcher **********/
echo Launching 'Mupen64Plus' at "%MUPEN64PLUS_HOME%"
call start-mupen64plus.bat %*

take-snapshot "%N64_SAVES_HOME%" eep mpk fla
