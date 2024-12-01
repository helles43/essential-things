@echo off
setlocal enabledelayedexpansion

:: Define URLs for the batch script and version info
set "URL=https://raw.githubusercontent.com/helles43/essential-things/main/client.bat"
set "VERSION_URL=https://raw.githubusercontent.com/helles43/essential-things/main/version.txt"
set "TEMP_FILE=%TEMP%\new_update.bat"
set "LOCAL_FILE=%~f0"
set "VERSION_FILE=%USERPROFILE%\Desktop\client_version.txt"

:: Check if the version file exists, otherwise create it and set the initial version
if not exist "!VERSION_FILE!" (
    echo 1.0 > "!VERSION_FILE!"
    set "LOCAL_VERSION=1.0"
    echo Created version file with initial version 1.0.
) else (
    set /p "LOCAL_VERSION="<"!VERSION_FILE!"
)

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

    :: Ask user if they want to upgrade
    echo A new version is available. Do you want to upgrade? (Yes/No)
    :askupgrade
    set /p upgrade=Choice: 
    if /I "!upgrade!"=="Yes" goto :upgrade
    if /I "!upgrade!"=="No" goto :skipupgrade
    goto :askupgrade

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

        :: Update version file with the new version
        echo !REMOTE_VERSION! > "!VERSION_FILE!"

        :: Notify user about successful update
        echo Update complete. The script has been replaced with the latest version.

        :: Start the new version of the script
        start "" "!LOCAL_FILE!"

        :: Exit the current script to prevent it from running
        exit
    ) else (
        echo Error: Failed to download the new script.
    )
) else (
    echo Error: Failed to retrieve version information from GitHub.
)

:skipupgrade
echo Welcome
pause

:end
