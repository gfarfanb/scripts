@echo OFF

set "__file=%~1"

if not exist "%__file%" (
    echo Source file not found at: '%__file%'
    goto :eof
)

setlocal

set __source_file_tag=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%-%RANDOM%_%RANDOM%
set __source_file_bat="%TEMP%\source-file-%__source_file_tag%.bat"

more "%__file%" > "%__source_file_bat%"

endlocal & call "%__source_file_bat%" & del "%__source_file_bat%"
