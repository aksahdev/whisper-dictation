@echo off
REM Install whisper-dictate globally on Windows
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

REM Copy .env if it exists
if exist ".env" (
    echo Copying .env file...
    copy /Y ".env" "%INSTALL_DIR%\.env"
) else (
    echo WARNING: .env file not found. You'll need to create it in %INSTALL_DIR%
    echo Example:
    echo   GROK_API_KEY=gsk-...
)

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
echo You can now run from anywhere:
echo   whisper-dictate --trigger voice
echo   whisper-dictate --trigger key --mode hold --hotkey numpad5
echo.
echo IMPORTANT: Close and reopen your terminal for PATH changes to take effect!
echo.
echo If you don't have a .env file, create one at:
echo   %INSTALL_DIR%\.env
echo With contents:
echo   GROK_API_KEY=gsk-your-key-here
echo.
pause

