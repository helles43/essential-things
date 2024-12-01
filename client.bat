@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
chcp 65001
title Essential-Things
cls

:: Define the hardcoded local version of the script
set "LOCAL_VERSION=2"  :: Change this version when you update the script
set "URL=https://raw.githubusercontent.com/helles43/essential-things/main/client.bat"
set "VERSION_URL=https://raw.githubusercontent.com/helles43/essential-things/main/version.txt"
set "TEMP_FILE=%TEMP%\new_update.bat"
set "LOCAL_FILE=%~f0"
set "BACKUP_FILE=%TEMP%\backup_client.bat"  :: Backup file for rollback

:: Fetch the latest version from GitHub's version.txt
echo Checking for updates...
powershell -Command "Invoke-WebRequest -Uri !VERSION_URL! -OutFile !TEMP_FILE!" >nul 2>&1

:: Check if the version file was successfully downloaded
if exist "!TEMP_FILE!" (
    for /f "delims=" %%i in (!TEMP_FILE!) do set "REMOTE_VERSION=%%i"
    
    if not defined REMOTE_VERSION (
        echo Error: Version information is empty.
        del /f /q "!TEMP_FILE!"
        goto :end
    )

    :: Delete the temp file after reading
    del /f /q "!TEMP_FILE!"

    echo Current version: !LOCAL_VERSION!
    echo Latest version: !REMOTE_VERSION!

    :: Check if the local version is greater than the remote version first
    if !LOCAL_VERSION! gtr !REMOTE_VERSION! (
        echo Your local version is newer than the remote version. Performing update...
        timeout /t 3 /nobreak > nul
        goto :upgrade
    )

    :: If the versions are equal, no action is needed
    if "!LOCAL_VERSION!"=="!REMOTE_VERSION!" (
        echo No update needed. The current version is the latest.
        timeout /t 3 /nobreak > nul
        goto :skipupgrade
    )

    :: If the remote version is greater than the local version, prompt for upgrade
    if !REMOTE_VERSION! gtr !LOCAL_VERSION! (
        echo A new version is available. Do you want to upgrade? (Yes/No)
        
        :askupgrade
        set /p upgrade=Choice: 
        if /I "!upgrade!"=="Yes" goto :upgrade
        if /I "!upgrade!"=="No" goto :skipupgrade
        goto :askupgrade

    )
) else (
    echo Error: Failed to retrieve version information from GitHub.
    goto :end
)

:upgrade
echo Downloading the latest version...

:: Download the updated batch file from GitHub
powershell -Command "Invoke-WebRequest -Uri !URL! -OutFile !TEMP_FILE!" >nul 2>&1

:: Check if the file was successfully downloaded
if exist "!TEMP_FILE!" (
    echo File downloaded successfully.

    :: Delete the old script immediately (removes old version info and script)
    del /f /q "!LOCAL_FILE!"

    :: Move the new file into place (new script will be directly replaced)
    move /Y "!TEMP_FILE!" "!LOCAL_FILE!" >nul

    :: Notify user about successful update
    echo Update complete. The script has been replaced with the latest version.
    timeout /t 3 /nobreak > nul

    :: Start the new version of the script
    start "" "!LOCAL_FILE!"

    :: Exit the current script to prevent it from running again
    exit
) else (
    echo Error: Failed to download the new script.
)

:skipupgrade
:: After checking for the update, continue with the rest of the script
cls
set banner=doom
cd banner/fonts/
type %banner%.ebanner
pause

:end
exit /b
