@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
title Essential-Things
cls

REM  --> Check for permissions
    IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (e
    echo This software needs administrative priviles to run certain apps and to confirm your software is legit and not knockoff...
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params= %*
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"

:: Define the hardcoded local version of the script
set "LOCAL_VERSION=14"  :: Change this version when you update the script
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
        powershell -c "[console]::beep(1000,200)"
        powershell -c "[console]::beep(1000,200)"
        powershell -c "[console]::beep(1000,200)"
        timeout /t 3 /nobreak > nul
        goto :upgrade
    )

    :: If the versions are equal, no action is needed
    if "!LOCAL_VERSION!"=="!REMOTE_VERSION!" (
        echo No update needed. The current version is the latest.
        powershell -c "[console]::beep(1000,200)"
        timeout /t 3 /nobreak > nul
        goto :skipupgrade
    )

    :: If the remote version is greater than the local version, prompt for upgrade
    if !REMOTE_VERSION! gtr !LOCAL_VERSION! (
        echo A new version is available. Do you want to upgrade? (Yes/No)
        powershell -c "[console]::beep(1000,200)"
        powershell -c "[console]::beep(1500,200)"
        
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
:reloadbanner
chcp 65001
cls
set /p banner=<settings/startupconfigs/bannerconfig.esetting
cd banner/fonts
type %banner%.ebanner
cd..
cd..
echo Essential-Things Command Line, Type "help" to display commands...

:commandline
set /p askcommand=[%COMPUTERNAME%]~ 
if %askcommand%==help goto :help
if %askcommand%==changebanner goto :changebanner
if %askcommand%==cleartemp goto :cleartemp
if %askcommand%==clearscreen goto :reloadbanner
if %askcommand%==repair goto :update
goto :commandline

:changebanner
echo.
echo =[Banners]==================================================================1/1=
echo doom.ebanner
echo orge.ebanner
echo small.ebanner
echo tmplr.ebanner
echo.
echo [!]: Only official banners are being displayed, to use custom one enter its name
echo.
set /p bannerselect=[changebanner]:type name of an banner~ 
cd settings/startupconfigs
delete bannerconfig.ebanner
echo %bannerselect%>>bannerconfig.esetting
cd..
cd..
goto :reloadbanner

:help
echo.
echo =[Help]=============================================1/1=
echo changebanner - Changes banner
echo update       - Manually updates client
echo repair       - Repairs client (Online)
echo cleartemp    - Clears temporary folders on this computer
echo clearscreen  - Clears all commands history on screen
echo.
goto :commandline

:cleartemp
echo.
echo cleartemp V0.1
ECHO Deleting User temp files ...
DEL /S /Q /F "%TEMP%\*.*"
DEL /S /Q /F "%TMP%\*.*"

ECHO Deleting Local temp files
DEL /S /Q /F "%USERPROFILE%\Local Settings\Temp\*.*"
DEL /S /Q /F "%LOCALAPPDATA%\Temp\*.*"

ECHO Deleting Windows temp files
DEL /S /Q /F "%WINDIR%\temp\*.*"
FOR /D %%p IN ("%WINDIR%\Temp\*") DO RMDIR /S /Q "%%p"
ECHO Cleanup completed !!!
echo.
goto :commandline

:end
exit /b
