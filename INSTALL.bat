@echo off
REM ========================================================================
REM Whisper Dictate - ONE-CLICK INSTALLER
REM Super simple: Just double-click and wait!
REM ========================================================================

REM Run setup in quick mode if API key exists, otherwise normal mode
echo.
echo ========================================================================
echo       WHISPER DICTATE - One-Click Installer
echo ========================================================================
echo.
echo Checking for existing configuration...

REM Check if API key already exists
if not "%GROK_API_KEY%"=="" (
    echo ✓ Found existing Groq API key
    echo Running quick reinstall...
    echo.
    call SETUP.bat --quick
) else if not "%OPENAI_API_KEY%"=="" (
    echo ✓ Found existing OpenAI API key
    echo Running quick reinstall...
    echo.
    call SETUP.bat --quick
) else (
    echo No API key found - running first-time setup...
    echo.
    call SETUP.bat
)

echo.
echo ========================================================================
echo Done! Check above for any errors.
echo ========================================================================
pause

