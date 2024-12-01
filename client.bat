@echo off
setlocal enabledelayedexpansion

:: Define the local version of the script (stored within the batch file)
set "LOCAL_VERSION=1.0"  :: Change this version when you update the script
set "URL=https://raw.githubusercontent.com/helles43/essential-things/main/client.bat"
set "VERSION_URL=https://raw.githubusercontent.com/helles43/essential-things/main/version.txt"
set "TEMP_FILE=%TEMP%\new_update.bat"
set "LOCAL_FILE=%~f0"

:: Fetch the latest version from GitHub's version.txt
echo Checking for updates...
powershell -Command "Invoke-WebRequest -Uri !VERSION_URL! -OutFile !TEMP_FILE!" >nul 2>&1

:: Check if the version file was successfully downloaded and is not empty
if exist "!TEMP_FILE!" (
    for /f "delims=" %%i in (!TEMP_FILE!) do set "REMOTE_VERSION=%%i"
    if not defined REMOTE_VERSION (
        echo Error: Version information is empty.
        del /f /q "!TEMP_FILE!"
        goto :end
    )

    :: Delete the temp file after reading
    del /f /q "!TEMP_FILE!"

    :: Compare the versions
    echo Current version: !LOCAL_VERSION!
    echo Latest version: !REMOTE_VERSION!

    :: Check if the remote version is greater than the local version
    if "!REMOTE_VERSION!" gtr "!LOCAL_VERSION!" (
        echo New version available, do you want to upgrade? (Yes/No)
        
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

            :: Temporarily rename the running script to free up the file name
            ren "!LOCAL_FILE!" "old_script.bat"

            :: Move the downloaded file to replace the original batch file
            move /Y "!TEMP_FILE!" "!LOCAL_FILE!"

            :: Notify user about successful update
            echo Update complete. The script has been replaced with the latest version.
        ) else (
            echo Error: Failed to download the new script.
        )
    ) else (
        echo No update needed. The current version is the latest.
    )
) else (
    echo Error: Failed to retrieve version information from GitHub.
)

:skipupgrade
echo Welcome
pause

:end
