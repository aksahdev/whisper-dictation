@echo off
setlocal enabledelayedexpansion
REM =============================================================
REM    Whisper Dictate - Quick API Key Updater
REM =============================================================
echo.
echo ========================================
echo   API Key Configuration
echo ========================================
echo.

REM Show current status
echo Current API Keys:
if defined GROK_API_KEY (
    echo   [√] Groq API key is set
) else (
    echo   [ ] Groq API key not set
)
if defined OPENAI_API_KEY (
    echo   [√] OpenAI API key is set
) else (
    echo   [ ] OpenAI API key not set
)
echo.

echo What would you like to do?
echo   1. Set/Update Groq API key (recommended)
echo   2. Set/Update OpenAI API key
echo   3. Remove Groq API key
echo   4. Remove OpenAI API key
echo   0. Exit
echo.
set /p CHOICE="Enter choice (0-4): "

if "%CHOICE%"=="1" goto :set_groq
if "%CHOICE%"=="2" goto :set_openai
if "%CHOICE%"=="3" goto :remove_groq
if "%CHOICE%"=="4" goto :remove_openai
if "%CHOICE%"=="0" goto :end
echo Invalid choice!
pause
goto :end

:set_groq
echo.
echo ----------------------------------------
echo Get your key: https://console.groq.com/keys
echo ----------------------------------------
echo.
set /p KEY="Paste your Groq API key: "

REM Clean up input (remove common mistakes)
set "KEY=!KEY: =!"
set "KEY=!KEY:GROK_API_KEY==!"
set "KEY=!KEY:"=!"

REM Validate format
echo !KEY! | findstr /R "^gsk[_-]" >nul 2>&1
if errorlevel 1 (
    echo.
    echo [ERROR] Invalid format! Groq keys start with "gsk-" or "gsk_"
    echo You entered: !KEY!
    pause
    goto :end
)

REM Save
setx GROK_API_KEY "!KEY!" >nul 2>&1
echo.
echo [√] Groq API key saved successfully!
echo.
echo IMPORTANT: Close and reopen your terminal for changes to take effect.
pause
goto :end

:set_openai
echo.
echo ----------------------------------------
echo Get your key: https://platform.openai.com/api-keys
echo ----------------------------------------
echo.
set /p KEY="Paste your OpenAI API key: "

REM Clean up input
set "KEY=!KEY: =!"
set "KEY=!KEY:OPENAI_API_KEY==!"
set "KEY=!KEY:"=!"

REM Validate format
echo !KEY! | findstr /R "^sk-" >nul 2>&1
if errorlevel 1 (
    echo.
    echo [ERROR] Invalid format! OpenAI keys start with "sk-"
    echo You entered: !KEY!
    pause
    goto :end
)

REM Save
setx OPENAI_API_KEY "!KEY!" >nul 2>&1
echo.
echo [√] OpenAI API key saved successfully!
echo.
echo IMPORTANT: Close and reopen your terminal for changes to take effect.
pause
goto :end

:remove_groq
setx GROK_API_KEY "" >nul 2>&1
echo.
echo [√] Groq API key removed.
pause
goto :end

:remove_openai
setx OPENAI_API_KEY "" >nul 2>&1
echo.
echo [√] OpenAI API key removed.
pause
goto :end

:end
endlocal
exit /b 0

