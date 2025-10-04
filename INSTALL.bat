@echo off
REM ========================================================================
REM Whisper Dictate - ONE-CLICK INSTALLER
REM The only installer you need! Just double-click and go!
REM ========================================================================

REM Check for --quick flag (skip all prompts for repeat installs)
set QUICK_MODE=0
if "%~1"=="--quick" set QUICK_MODE=1
if "%~1"=="/quick" set QUICK_MODE=1
if "%~1"=="-q" set QUICK_MODE=1

if %QUICK_MODE%==1 (
    echo.
    echo ========================================================================
    echo            WHISPER DICTATE - Quick Reinstall
    echo ========================================================================
    echo.
    goto :start_install
)

echo.
echo ========================================================================
echo            WHISPER DICTATE - One-Click Installer
echo ========================================================================
echo.
echo This will:
echo   1. Install whisper-dictate.exe globally
echo   2. Add to Windows PATH
echo   3. Configure your API key (if not already set)
echo   4. Create desktop shortcuts
echo   5. Set up AutoHotkey global hotkeys (optional)
echo.
echo TIP: Already installed? Just run again for instant update!
echo.
pause
echo.

:start_install

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

REM Copy alias and profiles
copy /Y "wd.bat" "%INSTALL_DIR%\wd.bat" >nul
copy /Y "wd-hold.bat" "%INSTALL_DIR%\wd-hold.bat" >nul
copy /Y "wd-toggle.bat" "%INSTALL_DIR%\wd-toggle.bat" >nul
copy /Y "wd-voice.bat" "%INSTALL_DIR%\wd-voice.bat" >nul

echo ✓ Binary installed successfully!
echo   - whisper-dictate.exe (full name)
echo   - wd.bat (quick alias)
echo   - wd-hold.bat, wd-toggle.bat, wd-voice.bat (quick profiles)
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
set EXISTING_GROQ=%GROK_API_KEY%
set EXISTING_OPENAI=%OPENAI_API_KEY%

if not "%EXISTING_GROQ%"=="" (
    echo ✓ Groq API key already configured: %EXISTING_GROQ:~0,20%...
    set BACKEND=grok
    if %QUICK_MODE%==1 goto :skip_api
    set /p RECONFIGURE="Reconfigure API key? (y/n): "
    if /i not "%RECONFIGURE%"=="y" goto :skip_api
)

if not "%EXISTING_OPENAI%"=="" (
    echo ✓ OpenAI API key already configured: %EXISTING_OPENAI:~0,20%...
    set BACKEND=openai
    if %QUICK_MODE%==1 goto :skip_api
    set /p RECONFIGURE="Reconfigure API key? (y/n): "
    if /i not "%RECONFIGURE%"=="y" goto :skip_api
)

REM No key configured, must set one
if "%EXISTING_GROQ%"=="" if "%EXISTING_OPENAI%"=="" (
    echo No API key found. Configuration required.
    echo.
    if %QUICK_MODE%==1 (
        echo ERROR: Quick mode requires an existing API key!
        echo Please run without --quick flag to configure.
        pause
        exit /b 1
    )
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
    
    REM Strip common mistakes
    set "API_KEY=%API_KEY:GROK_API_KEY=%"
    set "API_KEY=%API_KEY:grok_api_key=%"
    set "API_KEY=%API_KEY:GROQ_API_KEY=%"
    set "API_KEY=%API_KEY:groq_api_key=%"
    set "API_KEY=%API_KEY: =%"
    
    REM Validate Groq key format
    echo %API_KEY% | findstr /B /C:"gsk-" >nul 2>&1
    if errorlevel 1 (
        echo %API_KEY% | findstr /B /C:"gsk_" >nul 2>&1
        if errorlevel 1 (
            echo.
            echo ERROR: Invalid Groq API key format!
            echo Groq keys should start with "gsk-" or "gsk_"
            echo You entered: %API_KEY:~0,20%...
            echo.
            pause
            goto :skip_api
        )
    )
) else if "%API_CHOICE%"=="2" (
    set PROVIDER=OpenAI
    set VAR_NAME=OPENAI_API_KEY
    set BACKEND=openai
    echo.
    echo Get your OpenAI API key from: https://platform.openai.com/api-keys
    echo.
    set /p API_KEY="Enter your OpenAI API key (starts with sk-): "
    
    REM Strip common mistakes
    set "API_KEY=%API_KEY:OPENAI_API_KEY=%"
    set "API_KEY=%API_KEY:openai_api_key=%"
    set "API_KEY=%API_KEY: =%"
    
    REM Validate OpenAI key format
    echo %API_KEY% | findstr /B /C:"sk-" >nul 2>&1
    if errorlevel 1 (
        echo.
        echo ERROR: Invalid OpenAI API key format!
        echo OpenAI keys should start with "sk-"
        echo You entered: %API_KEY:~0,20%...
        echo.
        pause
        goto :skip_api
    )
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

REM Get proper Desktop location (handles OneDrive redirects)
for /f "usebackq tokens=3*" %%A in (`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop 2^>nul`) do set DESKTOP=%%A %%B
set DESKTOP=%DESKTOP:~0,-1%
call set DESKTOP=%DESKTOP%

REM Fallback to standard location if reg query failed
if "%DESKTOP%"=="" set DESKTOP=%USERPROFILE%\Desktop

REM Ensure Desktop folder exists
if not exist "%DESKTOP%" (
    echo WARNING: Desktop folder not found at %DESKTOP%
    echo Creating Start Menu shortcuts instead...
    set DESKTOP=%APPDATA%\Microsoft\Windows\Start Menu\Programs
)

REM Voice mode shortcut
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DESKTOP%\Whisper Dictate (Voice).lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\whisper-dictate.exe'; $Shortcut.Arguments = '--trigger voice --backend %BACKEND%'; $Shortcut.WorkingDirectory = '%INSTALL_DIR%'; $Shortcut.Description = 'Voice-activated dictation'; $Shortcut.Save()" 2>nul

REM Hotkey hold mode shortcut
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DESKTOP%\Whisper Dictate (Numpad5 Hold).lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\whisper-dictate.exe'; $Shortcut.Arguments = '--trigger key --mode hold --hotkey numpad5 --backend %BACKEND%'; $Shortcut.WorkingDirectory = '%INSTALL_DIR%'; $Shortcut.Description = 'Hold Numpad5 to dictate'; $Shortcut.Save()" 2>nul

REM Hotkey toggle mode shortcut
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DESKTOP%\Whisper Dictate (Numpad5 Toggle).lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\whisper-dictate.exe'; $Shortcut.Arguments = '--trigger key --mode toggle --hotkey numpad5 --backend %BACKEND%'; $Shortcut.WorkingDirectory = '%INSTALL_DIR%'; $Shortcut.Description = 'Toggle recording with Numpad5'; $Shortcut.Save()" 2>nul

if exist "%DESKTOP%\Whisper Dictate (Voice).lnk" (
    echo ✓ Shortcuts created successfully!
) else (
    echo WARNING: Shortcuts may not have been created properly
    echo You can still run: whisper-dictate --trigger voice
)
echo.

REM ===========================================
REM Optional: AutoHotkey Setup
REM ===========================================

REM Skip AutoHotkey prompt in quick mode
if %QUICK_MODE%==1 goto :skip_ahk

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

:skip_ahk

REM ===========================================
REM Test Installation
REM ===========================================
echo.
echo [Testing] Verifying installation...
echo.

REM Test if binary exists and runs
"%INSTALL_DIR%\whisper-dictate.exe" --help >nul 2>&1
if errorlevel 1 (
    echo WARNING: Binary test failed. Installation may be incomplete.
) else (
    echo ✓ Binary is working correctly
)

REM Test API key
if not "%EXISTING_GROQ%"=="" (
    echo ✓ API key configured: Groq
    set BACKEND=grok
)
if not "%EXISTING_OPENAI%"=="" (
    echo ✓ API key configured: OpenAI  
    set BACKEND=openai
)

echo.

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
echo Quick alias available:
echo   wd --trigger voice           (same as whisper-dictate)
echo   wd --trigger key --mode hold --hotkey numpad5
echo.
echo Quick profiles (no arguments needed!):
echo   wd-hold      - Numpad5 hold mode (RMS 0.010)
echo   wd-toggle    - Numpad5 toggle mode (RMS 0.010)
echo   wd-voice     - Voice activated mode (RMS 0.010)
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

