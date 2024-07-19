@echo OFF

setlocal

if [%1]==[] goto usage

set STRING="%*"
set TMPFILE="%TMP%\hash-%RANDOM%.tmp"
echo | set /p=%STRING% > %TMPFILE%
certutil -hashfile %TMPFILE% SHA256 | findstr /v "hash"
del %TMPFILE%
goto :eof

:usage
echo Usage: %0 string to be hashed

endlocal
