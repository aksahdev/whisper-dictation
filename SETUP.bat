@echo off
REM ========================================================================
REM Whisper Dictate - Complete Windows Setup
REM This script will set up everything you need in one go!
REM ========================================================================

echo.
echo ========================================================================
echo            WHISPER DICTATE - Windows 11 Setup Wizard
echo ========================================================================
echo.
echo This will:
echo   1. Install whisper-dictate.exe globally
echo   2. Add to Windows PATH
echo   3. Configure your API key
echo   4. Create desktop shortcuts
echo   5. Set up AutoHotkey global hotkeys (optional)
echo.
pause
echo.

REM ===========================================
REM Step 1: Check prerequisites
REM ===========================================
echo [Step 1/5] Checking prerequisites...
echo.

if not exist "dist\whisper-dictate.exe" (
    echo ERROR: whisper-dictate.exe not found!
    echo Please run PyInstaller first or download a release.
    pause
    exit /b 1
)

REM ===========================================
REM Step 2: Install binary
REM ===========================================
echo [Step 2/5] Installing whisper-dictate...
echo.

set INSTALL_DIR=%LOCALAPPDATA%\whisper-dictate
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo Installing to: %INSTALL_DIR%
copy /Y "dist\whisper-dictate.exe" "%INSTALL_DIR%\whisper-dictate.exe" >nul
if errorlevel 1 (
    echo ERROR: Failed to copy executable
    pause
    exit /b 1
)

echo ✓ Binary installed successfully!
echo.

REM ===========================================
REM Step 3: Add to PATH
REM ===========================================
echo [Step 3/5] Adding to Windows PATH...
echo.

powershell -Command "$oldPath = [Environment]::GetEnvironmentVariable('Path', 'User'); if ($oldPath -notlike '*whisper-dictate*') { [Environment]::SetEnvironmentVariable('Path', $oldPath + ';%INSTALL_DIR%', 'User'); Write-Host '✓ Added to PATH successfully!' } else { Write-Host '✓ Already in PATH' }"
echo.

REM ===========================================
REM Step 4: Configure API Key
REM ===========================================
echo [Step 4/5] Configuring API Key...
echo.

REM Check if already configured
set EXISTING_KEY=%GROK_API_KEY%
if not "%EXISTING_KEY%"=="" (
    echo API key already configured!
    set /p RECONFIGURE="Reconfigure? (y/n): "
    if /i not "%RECONFIGURE%"=="y" goto :skip_api
)

echo Choose your API provider:
echo   1. Groq (recommended - faster, cheaper)
echo   2. OpenAI
echo.
set /p API_CHOICE="Enter choice (1 or 2): "

if "%API_CHOICE%"=="1" (
    set PROVIDER=Groq
    set VAR_NAME=GROK_API_KEY
    set BACKEND=grok
    echo.
    echo Get your Groq API key from: https://console.groq.com/keys
    echo.
    set /p API_KEY="Enter your Groq API key (starts with gsk-): "
) else if "%API_CHOICE%"=="2" (
    set PROVIDER=OpenAI
    set VAR_NAME=OPENAI_API_KEY
    set BACKEND=openai
    echo.
    echo Get your OpenAI API key from: https://platform.openai.com/api-keys
    echo.
    set /p API_KEY="Enter your OpenAI API key (starts with sk-): "
) else (
    echo Invalid choice! Skipping API setup.
    set BACKEND=grok
    goto :skip_api
)

if "%API_KEY%"=="" (
    echo WARNING: No API key entered. You'll need to set it later.
    goto :skip_api
)

setx %VAR_NAME% "%API_KEY%" >nul
if errorlevel 1 (
    echo WARNING: Failed to set API key
    goto :skip_api
)

echo ✓ %PROVIDER% API key configured successfully!
echo.

:skip_api

REM ===========================================
REM Step 5: Create Shortcuts
REM ===========================================
echo [Step 5/5] Creating shortcuts...
echo.

REM Desktop shortcuts
set DESKTOP=%USERPROFILE%\Desktop

REM Voice mode shortcut
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DESKTOP%\Whisper Dictate (Voice).lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\whisper-dictate.exe'; $Shortcut.Arguments = '--trigger voice --backend %BACKEND%'; $Shortcut.WorkingDirectory = '%INSTALL_DIR%'; $Shortcut.Description = 'Voice-activated dictation'; $Shortcut.Save()"

REM Hotkey hold mode shortcut
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DESKTOP%\Whisper Dictate (Numpad5 Hold).lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\whisper-dictate.exe'; $Shortcut.Arguments = '--trigger key --mode hold --hotkey numpad5 --backend %BACKEND%'; $Shortcut.WorkingDirectory = '%INSTALL_DIR%'; $Shortcut.Description = 'Hold Numpad5 to dictate'; $Shortcut.Save()"

REM Hotkey toggle mode shortcut
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DESKTOP%\Whisper Dictate (Numpad5 Toggle).lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\whisper-dictate.exe'; $Shortcut.Arguments = '--trigger key --mode toggle --hotkey numpad5 --backend %BACKEND%'; $Shortcut.WorkingDirectory = '%INSTALL_DIR%'; $Shortcut.Description = 'Toggle recording with Numpad5'; $Shortcut.Save()"

echo ✓ Desktop shortcuts created!
echo.

REM ===========================================
REM Optional: AutoHotkey Setup
REM ===========================================
echo.
echo ========================================================================
echo Optional: Global Hotkey Setup with AutoHotkey
echo ========================================================================
echo.
echo Would you like to set up system-wide hotkeys?
echo This allows you to trigger dictation from anywhere with:
echo   - Win+F12: Voice dictation
echo   - Win+F11: Numpad5 hold mode
echo.
echo NOTE: Requires AutoHotkey (free, will open download page if needed)
echo.
set /p SETUP_AHK="Set up global hotkeys? (y/n): "

if /i "%SETUP_AHK%"=="y" (
    REM Check if AutoHotkey is installed
    where /q autohotkey.exe
    if errorlevel 1 (
        echo.
        echo AutoHotkey not found. Opening download page...
        start https://www.autohotkey.com/download/
        echo.
        echo After installing AutoHotkey, run this script again to set up hotkeys.
        pause
    ) else (
        REM Create AutoHotkey script
        echo Creating AutoHotkey script...
        (
            echo ; Whisper Dictate Global Hotkeys
            echo ; Press Win+F12 for voice mode
            echo ; Press Win+F11 for numpad5 hold mode
            echo.
            echo #F12::  ; Win+F12
            echo Run, %INSTALL_DIR%\whisper-dictate.exe --trigger voice --backend %BACKEND%
            echo return
            echo.
            echo #F11::  ; Win+F11
            echo Run, %INSTALL_DIR%\whisper-dictate.exe --trigger key --mode hold --hotkey numpad5 --backend %BACKEND%
            echo return
        ) > "%INSTALL_DIR%\whisper-dictate-hotkeys.ahk"
        
        REM Add to startup
        set STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
        powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%STARTUP%\whisper-dictate-hotkeys.lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\whisper-dictate-hotkeys.ahk'; $Shortcut.Save()"
        
        echo ✓ AutoHotkey script created and added to startup!
        echo.
        echo Starting AutoHotkey script...
        start "" "%INSTALL_DIR%\whisper-dictate-hotkeys.ahk"
        echo.
        echo Global hotkeys are now active:
        echo   Win+F12: Voice dictation
        echo   Win+F11: Numpad5 hold mode
    )
)

REM ===========================================
REM Installation Complete!
REM ===========================================
echo.
echo ========================================================================
echo                     INSTALLATION COMPLETE! 
echo ========================================================================
echo.
echo Installed to: %INSTALL_DIR%
echo.
echo Desktop shortcuts created:
echo   - Whisper Dictate (Voice).lnk
echo   - Whisper Dictate (Numpad5 Hold).lnk
echo   - Whisper Dictate (Numpad5 Toggle).lnk
echo.
echo Command line usage (after restarting terminal):
echo   whisper-dictate --trigger voice
echo   whisper-dictate --trigger key --mode hold --hotkey numpad5
echo   whisper-dictate --trigger key --mode toggle --hotkey space
echo.
if /i "%SETUP_AHK%"=="y" (
    echo Global hotkeys active:
    echo   Win+F12: Voice dictation
    echo   Win+F11: Numpad5 hold mode
    echo.
)
echo IMPORTANT: 
echo   - Close and reopen your terminal for PATH to take effect
echo   - API key is saved in Windows environment variables
echo   - Desktop shortcuts are ready to use immediately!
echo.
echo ========================================================================
echo.
pause

