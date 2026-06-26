@echo OFF

rem __usage_lib_page:
rem Extract the IP from ipconfig
rem
rem Arguments:
rem   %* - Input
rem Usage in script:
rem   call %SCRIPTS_HOME%\.win\win-ip

setlocal enabledelayedexpansion

set "_ps_cmd=Get-NetIPAddress -AddressFamily IPv4"

call :runps %_ps_cmd% _win_ip
Echo %_win_ip%
goto :eof


:runps <PassPSCMD> <Return value to be set as variable>
  for /F "usebackq tokens=*" %%i in (`Powershell %1`) do set "%2=%%i"
goto: eof

endlocal
