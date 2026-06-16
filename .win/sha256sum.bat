@echo OFF

rem __usage_lib_page:
rem Creates a hash (SHA256) from input
rem
rem Arguments:
rem   %* - Input
rem Usage in script:
rem   call %SCRIPTS_HOME%\.win\sha256sum <arg1> <arg2> <argn> # Relative call

setlocal

set "__input=%*"
set __hash_tag=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%-%RANDOM%_%RANDOM%
set "__hash_tmp=%SCRIPTS_TEMP_DIR%\hash-%__hash_tag%.tmp"

echo | set /p=%__input% > %__hash_tmp%
certutil -hashfile %__hash_tmp% SHA256 | findstr /v "hash"

endlocal & if exist "%__hash_tmp%" del "%__hash_tmp%"
