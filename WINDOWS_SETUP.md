# Windows 11 Setup Guide

This guide will help you set up Whisper Dictate on Windows 11.

## Quick Setup (5 minutes)

### Step 1: Prerequisites

1. **Install Python 3.8 or higher**
   - Download from: https://www.python.org/downloads/
   - ✅ **IMPORTANT:** Check "Add Python to PATH" during installation
   - Verify: Open PowerShell and run `python --version`

2. **Get API Key**
   - **Groq (Recommended):** https://console.groq.com/keys
   - **OpenAI (Alternative):** https://platform.openai.com/api-keys

### Step 2: Run Setup

Double-click `setup_windows.bat` or run in PowerShell:

```powershell
.\setup_windows.bat
```

This will:
- Create a Python virtual environment
- Install all required packages
- Set up the project structure

### Step 3: Configure API Keys

Create a file named `.env` in the project folder with your API key:

```ini
GROK_API_KEY=gsk-your-key-here
```

Or if using OpenAI:

```ini
OPENAI_API_KEY=sk-your-key-here
```

### Step 4: Test Installation

Activate the virtual environment and test:

```powershell
.\venv\Scripts\Activate.ps1
python dictate_min.py --print-only
```

Speak into your microphone. The transcription should appear in the console.

### Step 5: Run Dictation

**Quick start:** Double-click `run_dictate.bat`

**Or use command line:**

```powershell
.\venv\Scripts\Activate.ps1

# Voice-activated (speak to start)
python dictate_min.py --trigger voice

# Hotkey mode (press numpad5 to toggle recording)
python dictate_min.py --trigger key --mode toggle
```

## Troubleshooting Setup

### "Python is not recognized"

**Problem:** Windows can't find Python.

**Solution:**
1. Reinstall Python and check "Add Python to PATH"
2. Or manually add Python to PATH:
   - Search "Environment Variables" in Windows
   - Edit "Path" variable
   - Add: `C:\Users\YourName\AppData\Local\Programs\Python\Python3XX`

### "pip install failed"

**Problem:** Package installation errors.

**Solutions:**
```powershell
# Update pip
python -m pip install --upgrade pip

# Try installing packages individually
pip install openai sounddevice soundfile pynput numpy groq pyautogui python-dotenv

# If pywin32 fails (optional package):
pip install pyperclip  # Alternative clipboard support
```

### "Cannot run scripts" (PowerShell)

**Problem:** PowerShell execution policy blocks scripts.

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "No module named 'sounddevice'"

**Problem:** Virtual environment not activated.

**Solution:**
```powershell
# Activate it first
.\venv\Scripts\Activate.ps1
# You should see (venv) in your prompt
```

### Microphone Not Working

**Problem:** No audio detected or "Nothing recorded" error.

**Solutions:**
1. **Check Windows permissions:**
   - Settings → Privacy & Security → Microphone
   - Enable "Microphone access" and "Let apps access your microphone"

2. **Select correct microphone:**
   - Settings → System → Sound → Input
   - Test with Windows Voice Recorder app

3. **Adjust sensitivity:**
   ```powershell
   python dictate_min.py --silence-rms 0.01  # More sensitive
   ```

## Advanced Setup

### Create Desktop Shortcut

1. Right-click Desktop → New → Shortcut
2. Target: `C:\src\whisper-dictation\run_dictate.bat`
3. Name it "Whisper Dictate"
4. (Optional) Change icon: Right-click → Properties → Change Icon

### Global Hotkey with AutoHotkey

1. Install AutoHotkey: https://www.autohotkey.com/
2. Create `whisper-dictate.ahk`:

```autohotkey
; Press Win+F12 to start voice dictation
#F12::
Run, C:\src\whisper-dictation\run_dictate.bat
return
```

3. Double-click to run, or add to Windows Startup folder

### PowerShell Profile Alias

Add to your PowerShell profile (`notepad $PROFILE`):

```powershell
function Start-Dictation {
    param(
        [string]$Mode = "toggle"
    )
    
    $dictPath = "C:\src\whisper-dictation"
    Push-Location $dictPath
    
    & "$dictPath\venv\Scripts\python.exe" dictate_min.py --trigger key --mode $Mode
    
    Pop-Location
}

Set-Alias dictate Start-Dictation
```

Then use: `dictate` or `dictate -Mode hold`

### Run as Background Service

Use Windows Task Scheduler for background operation:

1. Open Task Scheduler
2. Create Basic Task → Name: "Whisper Dictate"
3. Trigger: "At log on"
4. Action: "Start a program"
   - Program: `C:\src\whisper-dictation\venv\Scripts\python.exe`
   - Arguments: `dictate.py --daemon --backend grok --mode toggle --hotkey space`
   - Start in: `C:\src\whisper-dictation`

## Customizing run_dictate.bat

Edit `run_dictate.bat` to change default settings:

```batch
REM Change this line:
python dictate_min.py --trigger key --mode toggle --backend grok --hotkey numpad5

REM Examples:
REM Voice-activated:
REM python dictate_min.py --trigger voice --backend grok

REM Hold spacebar to talk:
REM python dictate_min.py --trigger key --mode hold --hotkey space

REM Toggle with F9:
REM python dictate_min.py --trigger key --mode toggle --hotkey f9
```

## Performance Optimization

1. **Use Groq backend** - Much faster than OpenAI
   ```powershell
   python dictate_min.py --backend grok
   ```

2. **Reduce typing delay** - Already optimized in Windows version

3. **Close unnecessary apps** - Better focus management

4. **SSD recommended** - Faster temporary file operations

## Common Issues After Setup

### Text appears but in wrong window

**Solution:** Ensure target app is focused before speaking

### Elevated apps don't receive text

**Problem:** Running Notepad/VS Code as Administrator blocks input

**Solution:** Run your terminal/PowerShell as Administrator too

### Multiple monitor issues

**Problem:** PyAutoGUI has issues with multi-monitor setups

**Solution:** Use clipboard fallback (text auto-copies if typing fails)

## Next Steps

After successful setup:

1. Read [README_WINDOWS.md](README_WINDOWS.md) for full usage guide
2. Try different modes (voice, hold, toggle)
3. Test with different applications (Notepad, VS Code, browser)
4. Adjust sensitivity and timing parameters
5. Set up global hotkeys or desktop shortcuts

## Support

- Check [README_WINDOWS.md](README_WINDOWS.md) for usage examples
- Review original [README.md](README.md) for Linux/general info
- See [LICENSE](LICENSE) for terms of use

## Uninstall

To remove Whisper Dictate:

1. Delete the project folder
2. (Optional) Remove PowerShell aliases from `$PROFILE`
3. (Optional) Remove desktop shortcuts
4. (Optional) Remove Task Scheduler tasks

