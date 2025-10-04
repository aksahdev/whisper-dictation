@echo off
REM Install whisper-dictate globally on Windows (improved version)
echo ========================================
echo Whisper Dictate - Global Installation
echo ========================================
echo.

REM Create installation directory
set INSTALL_DIR=%LOCALAPPDATA%\whisper-dictate
echo Installing to: %INSTALL_DIR%
echo.

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

REM Copy executable
echo Copying executable...
copy /Y "dist\whisper-dictate.exe" "%INSTALL_DIR%\whisper-dictate.exe"
if errorlevel 1 (
    echo ERROR: Failed to copy executable
    pause
    exit /b 1
)

REM Copy setup script
copy /Y "setup-api-key.bat" "%INSTALL_DIR%\setup-api-key.bat"

REM Add to PATH
echo.
echo Adding to PATH...
powershell -Command "$oldPath = [Environment]::GetEnvironmentVariable('Path', 'User'); if ($oldPath -notlike '*whisper-dictate*') { [Environment]::SetEnvironmentVariable('Path', $oldPath + ';%INSTALL_DIR%', 'User'); Write-Host 'Added to PATH successfully!' } else { Write-Host 'Already in PATH' }"

echo.
echo ========================================
echo Installation Complete!
echo ========================================
echo.
echo The 'whisper-dictate.exe' is now installed at:
echo   %INSTALL_DIR%
echo.
echo NEXT STEP: Configure your API key
echo   Run: %INSTALL_DIR%\setup-api-key.bat
echo   (You only need to do this once!)
echo.
echo After setup, you can run from anywhere:
echo   whisper-dictate --trigger voice
echo   whisper-dictate --trigger key --mode hold --hotkey numpad5
echo.
echo Close and reopen your terminal after API key setup!
echo.

REM Ask if they want to set up API key now
set /p SETUP_NOW="Would you like to set up your API key now? (y/n): "
if /i "%SETUP_NOW%"=="y" (
    echo.
    call "%INSTALL_DIR%\setup-api-key.bat"
)

pause

