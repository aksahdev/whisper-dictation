@echo off
REM Setup API keys for Whisper Dictate
echo ========================================
echo Whisper Dictate - API Key Setup
echo ========================================
echo.
echo This will configure your API key as a Windows environment variable.
echo You only need to do this ONCE.
echo.

REM Check if already configured
set EXISTING_KEY=%GROK_API_KEY%
if not "%EXISTING_KEY%"=="" (
    echo Current Groq API key: %EXISTING_KEY:~0,20%...
    echo.
    set /p RECONFIGURE="Reconfigure? (y/n): "
    if /i not "%RECONFIGURE%"=="y" goto :end
)

echo.
echo Choose your API provider:
echo   1. Groq (recommended - faster, cheaper)
echo   2. OpenAI
echo.
set /p CHOICE="Enter choice (1 or 2): "

if "%CHOICE%"=="1" (
    set PROVIDER=Groq
    set VAR_NAME=GROK_API_KEY
    echo.
    echo Get your Groq API key from: https://console.groq.com/keys
    echo.
    set /p API_KEY="Enter your Groq API key (starts with gsk-): "
) else if "%CHOICE%"=="2" (
    set PROVIDER=OpenAI
    set VAR_NAME=OPENAI_API_KEY
    echo.
    echo Get your OpenAI API key from: https://platform.openai.com/api-keys
    echo.
    set /p API_KEY="Enter your OpenAI API key (starts with sk-): "
) else (
    echo Invalid choice!
    pause
    exit /b 1
)

if "%API_KEY%"=="" (
    echo ERROR: API key cannot be empty
    pause
    exit /b 1
)

echo.
echo Setting %PROVIDER% API key as Windows environment variable...
setx %VAR_NAME% "%API_KEY%" >nul

if errorlevel 1 (
    echo ERROR: Failed to set environment variable
    pause
    exit /b 1
)

echo.
echo ========================================
echo Success!
echo ========================================
echo.
echo Your %PROVIDER% API key has been saved to Windows environment variables.
echo It will be available in all new terminal sessions.
echo.
echo You can now run whisper-dictate from anywhere:
echo   whisper-dictate --trigger voice
echo   whisper-dictate --trigger key --mode hold --hotkey numpad5
echo.
if "%CHOICE%"=="2" (
    echo Note: Add --backend openai when using OpenAI
)
echo.
echo IMPORTANT: Close and reopen your terminal for the key to be available!
echo.

:end
pause

