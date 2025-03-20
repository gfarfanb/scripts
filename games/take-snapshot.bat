@echo OFF

rem Label [profilesnapshot]
rem This is an alternative option to create the snapshot
rem when !delayed! expansion ('setlocal enableDelayedExpansion')
rem is enabled. That setup removes '!' to the save filenames.
rem
rem In this case we need to define (somewhere) a variable using this code:
rem     for /f "delims=" %%a in ('sha256sum "<save-file-without-exclamation-marks>"') do (
rem         set "_profile_save_files[%%a]=<original-save-file>"
rem     )

setlocal enableDelayedExpansion

set "_saves_home=%~1\"
set "_snapshots_home=%_saves_home%snapshots\"

if "%SNAPSHOTS_TO_KEEP%"=="" (
    set /a _number_to_keep=3
) else (
    set /a _number_to_keep=%SNAPSHOTS_TO_KEEP%
)

rem Group save files per name (without extension)
rem and collect extensions from files
rem _save_names[<name-hash>]=1
rem _save_ids[<idx>]=<save-name>
rem _save_exts[<ext-hash>]=1
rem _ext_ids[<idx>]=<save-ext>
set /a _save_count=0
set /a _ext_count=0

for /f "delims=" %%N in ('dir %_saves_home%* /b') do (
    
    if exist "%_saves_home%%%~N"\ (
        rem
    ) else if exist "%_saves_home%%%~N" (
        for %%f in ("%%~N") do set "_save_name=%%~nf"

        if not "!_save_name!" == "" (
            for /f "delims=" %%a in ('sha256sum "!_save_name!"') do (
                if "!_save_names[%%a]!"=="" (
                    set _save_names[%%a]=1
                    set /a _save_count+=1
                    set _save_ids[!_save_count!]=!_save_name!

                    echo save: !_save_name!
                )
            )
        )

        for %%e in ("%%~N") do set "_save_ext=%%~xe"

        if not "!_save_ext!" == "" (
            for /f "delims=" %%a in ('sha256sum "!_save_ext!"') do (
                if "!_save_exts[%%a]!"=="" (
                    set _save_exts[%%a]=1
                    set /a _ext_count+=1
                    set _ext_ids[!_ext_count!]=!_save_ext!

                    echo save: !_save_ext!
                )
            )
        )
    )
)

if %_save_count% lss 1 goto nosavefile
goto selectsave


:selectsave

echo:
echo Choose a save file to create a snapshot:
for /L %%i in (1,1,%_save_count%) do (
    echo %%i^) !_save_ids[%%i]!
)

set /a _default_save_file=%_save_count%+1
echo %_default_save_file%^) ^(default^) ^<skip snapshot^>

set "_save_file_idx="
set /P _save_file_idx="save-index> "
if "%_save_file_idx%"=="" set _save_file_idx=%_default_save_file%

set _save_selected=!_save_ids[%_save_file_idx%]!

if "%_save_selected%" == "" goto nosavefile
goto createsnapshot


:createsnapshot

if exist "%_snapshots_home%" ( echo: ) else ( mkdir "%_snapshots_home%" )

set /a _profile_count=0
set _tmp_tag=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%-%RANDOM%_%RANDOM%
set _profile_tmp="%TEMP%\profile-temp-%_tmp_tag%.bat"

for /L %%i in (1,1,%_ext_count%) do (
    set "_save_ext=!_ext_ids[%%i]!"
    set "_save_file=%_save_selected%!_save_ext!"
    set _snapshot_ext=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%-%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
    set "_snapshot_file=!_save_file!.!_snapshot_ext!"
    set "_save_file_path=%_saves_home%!_save_file!"
    set "_snapshot_file_path=%_snapshots_home%!_snapshot_file!"

    if exist "!_save_file_path!" (
        echo Creating snapshot: "!_snapshot_file_path!"
        copy "!_save_file_path!" "!_snapshot_file_path!"

        for /f "skip=%_number_to_keep% eol=: delims=" %%F in ('dir /b /o-e /a-d "%_snapshots_home%!_save_file!*"') do @del "%_snapshots_home%%%F"
    ) else (
        set /a _profile_count+=1
        echo set "_profile_save[!_profile_count!]=!_save_file!" >> %_profile_tmp%
    )
)

if %_profile_count% gtr 0 goto profilesnapshot
goto :eof


:nosavefile
echo Snapshot not created
goto :eof

endlocal


:profilesnapshot

call "%_profile_tmp%"
del "%_profile_tmp%"

for /L %%i in (1,1,%_profile_count%) do (
    set "_save_file=!_profile_save[%%i]!"

    for /f "delims=" %%a in ('sha256sum "!_save_file!"') do (
        set "_save_file=!_profile_save_files[%%a]!"

        if not "!_save_file!"=="" (
            set _snapshot_ext=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%-%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
            set "_snapshot_file=!_save_file!.!_snapshot_ext!"
            set "_snapshot_file_path=%_snapshots_home%!_snapshot_file!"
            set "_save_file_path=%_saves_home%!_save_file!"

            if exist "!_save_file_path!" (
                echo Creating profile snapshot: "!_snapshot_file_path!"
                copy "!_save_file_path!" "!_snapshot_file_path!"

                for /f "skip=%_number_to_keep% eol=: delims=" %%F in ('dir /b /o-e /a-d "%_snapshots_home%!_save_file!*"') do @del "%_snapshots_home%%%F"
            )
        )
    )
)
