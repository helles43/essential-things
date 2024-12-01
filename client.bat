@echo off
setlocal enabledelayedexpansion

:: Define the hardcoded local version of the script as an integer (e.g., 10 instead of 1.0)
set "LOCAL_VERSION=2"  :: Change this version when you update the script (as an integer without dot)
set "URL=https://raw.githubusercontent.com/helles43/essential-things/main/client.bat"
set "VERSION_URL=https://raw.githubusercontent.com/helles43/essential-things/main/version.txt"
set "TEMP_FILE=%TEMP%\new_update.bat"
set "LOCAL_FILE=%~f0"

:: Fetch the latest version from GitHub's version.txt
echo Checking for updates...

:: Use Invoke-WebRequest to fetch the version file, suppress output but capture errors
powershell -Command "try { Invoke-WebRequest -Uri !VERSION_URL! -OutFile !TEMP_FILE! } catch { exit 1 }" >nul 2>&1

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

    :: Comparing version numbers (No need for dot removal now)
    echo Comparing version numbers...

    :: Skip upgrade prompt if versions are the same
    if !REMOTE_VERSION! neq !LOCAL_VERSION! (
        :: Only show upgrade prompt if the remote version is greater than the local version
        if !REMOTE_VERSION! gtr !LOCAL_VERSION! (
            echo A new version is available. Do you want to upgrade? (Yes/No)
            
            :askupgrade
            set /p upgrade=Choice: 
            if /I "!upgrade!"=="Yes" goto :upgrade
            if /I "!upgrade!"=="No" goto :skipupgrade
            goto :askupgrade

            :upgrade
            echo Downloading the latest version...

            :: Download the updated batch file from GitHub
            powershell -Command "try { Invoke-WebRequest -Uri !URL! -OutFile !TEMP_FILE! } catch { exit 1 }" >nul 2>&1

            :: Check if the file was successfully downloaded
            if exist "!TEMP_FILE!" (
                echo File downloaded successfully.

                :: Delete the old script immediately (removes old version info and script)
                del /f /q "!LOCAL_FILE!"

                :: Move the new file into place (new script will be directly replaced)
                move /Y "!TEMP_FILE!" "!LOCAL_FILE!" >nul

                :: Notify user about successful update
                echo Update complete. The script has been replaced with the latest version.

                :: Start the new version of the script
                start "" "!LOCAL_FILE!"

                :: Exit the current script to prevent it from running
                exit
            ) else (
                echo Error: Failed to download the new script.
            )
        )
    ) else (
        echo You already have the latest version. No update needed.
    )
) else (
    echo Error: Failed to retrieve version information from GitHub. Please check your internet connection or the GitHub URL.
)

:skipupgrade
echo Welcome
pause

:end
exit /b
