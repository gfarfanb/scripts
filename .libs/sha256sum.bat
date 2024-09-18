@echo OFF

setlocal

set __input="%*"
set __hash_tag=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%-%RANDOM%_%RANDOM%
set __hash_tmp="%TEMP%\hash-%__hash_tag%.tmp"

echo | set /p=%__input% > %__hash_tmp%
certutil -hashfile %__hash_tmp% SHA256 | findstr /v "hash"

del %__hash_tmp%

endlocal
