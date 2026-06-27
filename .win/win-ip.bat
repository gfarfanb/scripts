@echo OFF

rem __usage_lib_page:
rem Extract the IP from ipconfig
rem
rem Arguments:
rem   %* - Input
rem Usage in script:
rem   call %SCRIPTS_HOME%\.win\win-ip

setlocal

set "_ps_cmd=Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $(Get-NetConnectionProfile ^| Select-Object -ExpandProperty InterfaceIndex) ^| Select-Object -ExpandProperty IPAddress"

powershell %_ps_cmd%

endlocal
