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
if '%errorlevel%' NEQ '0' (
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
set "LOCAL_VERSION=15"  :: Change this version when you update the script
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
        echo ===================================================
        echo A new version is available. Do you want to upgrade?
        echo Update Notes:
        curl https://raw.githubusercontent.com/helles43/essential-things/refs/heads/main/updatenotes.txt
        echo.
        echo When you update, all settings will go to deafult
        echo ===================================================
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
rmdir settings
mkdir settings
cd settings
mkdir startupconfigs
cd startupconfigs
echo small>>bannerconfig.esetting
cd..
cd..

rmdir themes
mkdir themes
cd themes
mkdir banners
cd banners

Powershell Invoke-WebRequest -Uri "https://raw.githubusercontent.com/helles43/essential-things/refs/heads/main/tmplr.ebanner" -OutFile ".\tmplr.ebanner"
Powershell Invoke-WebRequest -Uri "https://raw.githubusercontent.com/helles43/essential-things/refs/heads/main/orge.ebanner" -OutFile ".\orge.ebanner"
Powershell Invoke-WebRequest -Uri "https://raw.githubusercontent.com/helles43/essential-things/refs/heads/main/doom.ebanner" -OutFile ".\doom.ebanner"
Powershell Invoke-WebRequest -Uri "https://raw.githubusercontent.com/helles43/essential-things/refs/heads/main/small.ebanner" -OutFile ".\small.ebanner"

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
cd themes/banners
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
if %askcommand%==networking goto :networking
goto :commandline

:changebanner
echo.
echo =[Banners]=============================================================1/1=
echo doom.ebanner
echo orge.ebanner
echo small.ebanner
echo tmplr.ebanner
echo.
echo Only official banners are being displayed, to use custom one enter its name
echo ===========================================================================
echo.
set /p bannerselect=[changebanner]:type name of an banner~ 
cd settings/startupconfigs
delete bannerconfig.ebanner
echo %bannerselect%>>bannerconfig.esetting
cd..
cd..
goto :reloadbanner


:networking
echo.
echo networking V0.1
echo ==================================================================================================
echo 1. Run all
echo 2. netstat -           Displays active connections and listening ports
echo 3. netstat -a          Shows all active connections and listening ports
echo 4. netstat -b          Shows the executable involved in creating each connection or listening port
echo 5. netstat -n          Displays addresses and port numbers in numerical form
echo 6. netstat -o          Shows the process ID (PID) associated with each connection
echo 7. netstat -p tcp      Shows connections for the TCP protocol
echo 8. netstat -p udp      Shows connections for the UDP protocol
echo 9. netstat -r          Displays the routing table
echo 10. netstat -s         Displays per-protocol statistics (e.g., TCP, UDP, etc.)
echo 11. netstat -t         Shows TCP connections
echo 12. netstat -u         Shows UDP connections
echo 13. netstat -v         Provides verbose output with detailed information
echo 14. netstat -x         Displays Unix domain socket connections (on Unix-based systems)
echo 15. netstat -y         Displays the TCP connection template in use
echo 16. netstat -h         Displays help information
echo ===================================================================================================
echo.
set /p nchoice=[networking]:select a number to run command~ 

if "%nchoice%"=="1" goto allCommands
if "%nchoice%"=="2" goto runNetstat
if "%nchoice%"=="3" goto runNetstatA
if "%nchoice%"=="4" goto runNetstatB
if "%nchoice%"=="5" goto runNetstatN
if "%nchoice%"=="6" goto runNetstatO
if "%nchoice%"=="7" goto runNetstatPtcp
if "%nchoice%"=="8" goto runNetstatPudp
if "%nchoice%"=="9" goto runNetstatR
if "%nchoice%"=="10" goto runNetstatS
if "%nchoice%"=="11" goto runNetstatT
if "%nchoice%"=="12" goto runNetstatU
if "%nchoice%"=="13" goto runNetstatV
if "%nchoice%"=="14" goto runNetstatX
if "%nchoice%"=="15" goto runNetstatY
if "%nchoice%"=="16" goto runNetstatH

:allCommands
echo Running all netstat commands...
netstat
netstat -a
netstat -b
netstat -n
netstat -o
netstat -p tcp
netstat -p udp
netstat -r
netstat -s
netstat -t
netstat -u
netstat -v
netstat -x
netstat -y
netstat -h
pause
goto end

:runNetstat
echo Running: netstat
echo Displays active connections and listening ports.
netstat
pause
goto end

:runNetstatA
echo Running: netstat -a
echo Shows all active connections and listening ports.
netstat -a
pause
goto end

:runNetstatB
echo Running: netstat -b
echo Shows the executable involved in creating each connection or listening port.
netstat -b
pause
goto end

:runNetstatN
echo Running: netstat -n
echo Displays addresses and port numbers in numerical form.
netstat -n
pause
goto end

:runNetstatO
echo Running: netstat -o
echo Shows the process ID (PID) associated with each connection.
netstat -o
pause
goto end

:runNetstatPtcp
echo Running: netstat -p tcp
echo Shows connections for the TCP protocol.
netstat -p tcp
pause
goto end

:runNetstatPudp
echo Running: netstat -p udp
echo Shows connections for the UDP protocol.
netstat -p udp
pause
goto end

:runNetstatR
echo Running: netstat -r
echo Displays the routing table.
netstat -r
pause
goto end

:runNetstatS
echo Running: netstat -s
echo Displays per-protocol statistics (e.g., TCP, UDP, etc.).
netstat -s
pause
goto end

:runNetstatT
echo Running: netstat -t
echo Shows TCP connections.
netstat -t
pause
goto end

:runNetstatU
echo Running: netstat -u
echo Shows UDP connections.
netstat -u
pause
goto end

:runNetstatV
echo Running: netstat -v
echo Provides verbose output with detailed information.
netstat -v
pause
goto end

:runNetstatX
echo Running: netstat -x
echo Displays Unix domain socket connections (on Unix-based systems).
netstat -x
pause
goto end

:runNetstatY
echo Running: netstat -y
echo Displays the TCP connection template in use.
netstat -y
pause
goto end

:runNetstatH
echo Running: netstat -h
echo Displays help information.
netstat -h
pause
goto end


:help
echo.
echo =[Help]=============================================1/1=
echo changebanner - Changes banner
echo update       - Manually updates client
echo repair       - Repairs client (Online)
echo cleartemp    - Clears temporary folders on this computer
echo clearscreen  - Clears all commands history on screen
echo networking   - Networking tools
echo ========================================================
echo.
goto :commandline

:cleartemp
echo.
echo cleartemp V0.1
echo ============================
ECHO Deleting User temp files ...
DEL /S /Q /F "%TEMP%\*.*"
DEL /S /Q /F "%TMP%\*.*"

ECHO Deleting Local temp files
DEL /S /Q /F "%USERPROFILE%\Local Settings\Temp\*.*"
DEL /S /Q /F "%LOCALAPPDATA%\Temp\*.*"

ECHO Deleting Windows temp files
DEL /S /Q /F "%WINDIR%\temp\*.*"
FOR /D %%p IN ("%WINDIR%\Temp\*") DO RMDIR /S /Q "%%p"
echo =====================
ECHO Cleanup completed !!!
echo.
goto :commandline

:end
exit /b
