@echo off
REM Windows Setup Script for Whisper Dictate
echo ========================================
echo Whisper Dictate - Windows 11 Setup
echo ========================================
echo.

REM Check Python installation
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.8+ from https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation
    pause
    exit /b 1
)

echo Python detected:
python --version
echo.

REM Create virtual environment
echo Creating virtual environment...
if exist .venv (
    echo Virtual environment already exists, skipping...
) else if exist venv (
    echo Virtual environment already exists (old venv), skipping...
) else (
    python -m venv .venv
    if errorlevel 1 (
        echo ERROR: Failed to create virtual environment
        pause
        exit /b 1
    )
    echo Virtual environment created successfully
)
echo.

REM Activate virtual environment and install packages
echo Installing Python packages...
if exist .venv\Scripts\activate.bat (
    call .venv\Scripts\activate.bat
) else (
    call venv\Scripts\activate.bat
)
if errorlevel 1 (
    echo ERROR: Failed to activate virtual environment
    pause
    exit /b 1
)

python -m pip install --upgrade pip
pip install -r requirements.txt
if errorlevel 1 (
    echo ERROR: Failed to install requirements
    pause
    exit /b 1
)

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Create a .env file with your API keys:
echo    GROK_API_KEY=gsk-...
echo    OPENAI_API_KEY=sk-...
echo.
echo 2. Test the installation:
echo    venv\Scripts\activate
echo    python dictate_min.py --print-only
echo.
echo 3. Run dictation:
echo    python dictate_min.py --trigger voice
echo    or
echo    python dictate_min.py --trigger key --mode toggle
echo.
echo See README_WINDOWS.md for more information
echo ========================================
pause

