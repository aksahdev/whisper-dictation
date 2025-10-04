@echo off
REM Quick start script for Whisper Dictate on Windows
REM Edit this file to customize your default settings

cd /d "%~dp0"

REM Check if virtual environment exists
if not exist .venv (
    if not exist venv (
        echo ERROR: Virtual environment not found
        echo Please run: uv venv
        echo Then: uv pip install -r requirements.txt
        pause
        exit /b 1
    )
    call venv\Scripts\activate.bat
    goto :run
)

REM Activate virtual environment
call .venv\Scripts\activate.bat
:run

REM Default configuration - edit these lines to customize:
REM   --trigger: voice or key
REM   --mode: hold or toggle (only for key trigger)
REM   --backend: grok or openai
REM   --hotkey: numpad5, space, f9, etc.

python dictate_min.py --trigger key --mode toggle --backend grok --hotkey numpad5

REM Keep window open if there was an error
if errorlevel 1 (
    echo.
    echo Press any key to exit...
    pause >nul
)

