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

if "%SNAPSHOTS_TO_KEEP%"=="" set SNAPSHOTS_TO_KEEP=10
set /a _number_to_keep=%SNAPSHOTS_TO_KEEP%


rem Collecting extensions from args
rem _save_exts[<idx>]=<ext>
set /a _arg_idx=1
set /a _ext_count=0

for %%x in (%*) do (
    if !_arg_idx! gtr 1 (
        set /a _ext_count+=1
        set "_save_exts[!_ext_count!]=%%~x"
    )
    set /a _arg_idx+=1
)


rem Date-time variables
set _year=%date:~-4%
set _month=%date:~4,2%
if "%_month:~0,1%" == " " set _month=0%_month:~1,1%
set _day=%date:~7,2%
if "%_day:~0,1%" == " " set _day=0%_day:~1,1%

set _hour=%time:~0,2%
if "%_hour:~0,1%" == " " set _hour=0%_hour:~1,1%
set _mins=%time:~3,2%
if "%_mins:~0,1%" == " " set _mins=0%_mins:~1,1%
set _secs=%time:~6,2%
if "%_secs:~0,1%" == " " set _secs=0%_secs:~1,1%


rem Grouping save files per name (without extension)
rem _save_names[<name-hash>]=1
rem _save_ids[<idx>]=<save-name>
set /a _save_count=0

for /L %%i in (1,1,%_ext_count%) do (
    set "_save_ext=!_save_exts[%%i]!"

    for /f "delims=" %%N in ('dir %_saves_home%*.!_save_ext! /b') do (
        set "_save_file_name=%%~N"
        call eval set "_save_name=^!_save_file_name:.!_save_ext!=^!"

        for /f "delims=" %%a in ('sha256sum "!_save_name!"') do (
            if "!_save_names[%%a]!"=="" (
                set _save_names[%%a]=1
                set /a _save_count+=1
                set _save_ids[!_save_count!]=!_save_name!
            )
        )
    )
)

if %_save_count% lss 1 goto nosavefile
goto selectsave


:selectsave

echo:
for /L %%i in (1,1,%_save_count%) do (
    echo [%%i] "!_save_ids[%%i]!"
)

set /a _default_save_file=%_save_count%+1
echo [%_default_save_file%] "<skip snapshot>"

set /P _save_file_idx="Choose a save file to create snapshot (default [%_default_save_file%]): "
if "%_save_file_idx%"=="" set _save_file_idx=%_default_save_file%

set _save_selected=!_save_ids[%_save_file_idx%]!

if "%_save_selected%" == "" goto nosavefile
goto createsnapshot


:createsnapshot

if exist "%_snapshots_home%" ( echo: ) else ( mkdir "%_snapshots_home%" )

set /a _profile_count=0
set _profile_tmp="%TEMP%\profile-temp-%_year%%_month%%_day%%_hour%%_mins%%_secs%.bat"

for /L %%i in (1,1,%_ext_count%) do (
    set "_save_ext=!_save_exts[%%i]!"
    set "_save_file=%_save_selected%.!_save_ext!"
    set "_snapshot_file=!_save_file!.%_year%%_month%%_day%-%_hour%%_mins%%_secs%"
    set "_snapshot_file_path=%_snapshots_home%!_snapshot_file!"
    set "_save_file_path=%_saves_home%!_save_file!"

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
            set "_snapshot_file=!_save_file!.%_year%%_month%%_day%-%_hour%%_mins%%_secs%"
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
