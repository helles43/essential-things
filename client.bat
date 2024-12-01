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
powershell -Command "Invoke-WebRequest -Uri !VERSION_URL! -OutFile !TEMP_FILE!"

:: Check if the version file was successfully downloaded
if exist "!TEMP_FILE!" (
    set /p "REMOTE_VERSION="<"!TEMP_FILE!"
    del /f /q "!TEMP_FILE!"

    :: Compare the versions
    echo Current version: !LOCAL_VERSION!
    echo Latest version: !REMOTE_VERSION!

    if !REMOTE_VERSION! gtr !LOCAL_VERSION! (
        echo New version available, do you want to upgrade?
        set /p upgrade= Yes/No? 
        if %upgrade%==Yes goto :upgrade
        if %upgrade%==yes goto :upgrade
        if %upgrade%==No goto :skipupgrade
        if %upgrade%==no goto :skipupgrade
        goto :askupgrade

        :upgrade

        :: Download the updated batch file from GitHub
        powershell -Command "Invoke-WebRequest -Uri !URL! -OutFile !TEMP_FILE!"

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

echo welcome
pause
