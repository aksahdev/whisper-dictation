@echo off
REM Quick API Key Setup Tool
echo.
echo ========================================
echo    Whisper Dictate - API Key Setup
echo ========================================
echo.

REM Check existing keys
if not "%GROK_API_KEY%"=="" (
    echo Current Groq key: %GROK_API_KEY:~0,20%...
)
if not "%OPENAI_API_KEY%"=="" (
    echo Current OpenAI key: %OPENAI_API_KEY:~0,20%...
)
echo.

echo Choose provider:
echo   1. Groq (recommended)
echo   2. OpenAI
echo.
set /p CHOICE="Enter choice (1 or 2): "

if "%CHOICE%"=="1" (
    echo.
    echo Get your key from: https://console.groq.com/keys
    echo.
    set /p KEY="Paste your Groq API key: "
    
    REM Clean up
    set "KEY=%KEY:GROK_API_KEY=%"
    set "KEY=%KEY: =%"
    
    REM Validate
    echo %KEY% | findstr /B "gsk" >nul 2>&1
    if errorlevel 1 (
        echo ERROR: Invalid key format (should start with gsk-)
        pause
        exit /b 1
    )
    
    setx GROK_API_KEY "%KEY%"
    echo.
    echo ✓ Groq API key saved!
    
) else if "%CHOICE%"=="2" (
    echo.
    echo Get your key from: https://platform.openai.com/api-keys
    echo.
    set /p KEY="Paste your OpenAI API key: "
    
    REM Clean up
    set "KEY=%KEY:OPENAI_API_KEY=%"
    set "KEY=%KEY: =%"
    
    REM Validate
    echo %KEY% | findstr /B "sk-" >nul 2>&1
    if errorlevel 1 (
        echo ERROR: Invalid key format (should start with sk-)
        pause
        exit /b 1
    )
    
    setx OPENAI_API_KEY "%KEY%"
    echo.
    echo ✓ OpenAI API key saved!
    
) else (
    echo Invalid choice!
    pause
    exit /b 1
)

echo.
echo ========================================
echo Done! Close and reopen your terminal.
echo Then test with: whisper-dictate --help
echo ========================================
pause

