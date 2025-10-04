# Whisper Dictate - Windows 11 Edition

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Speech-to-text dictation for Windows 11. Uses Groq or OpenAI Whisper API for fast, accurate transcription.

**Core features:**
- Voice-activated one-shot (auto start/stop on speech/silence)
- Hotkey push-to-talk or toggle (default: numpad5)
- Multiple text input methods with automatic fallback
- Works with any Windows application

Core scripts:
- `dictate_min.py` - Minimal version with voice activation and hotkey support
- `dictate.py` - Full-featured with daemon mode

## Installation

### 1. Install Python Dependencies

```powershell
# Create virtual environment (recommended)
python -m venv venv
.\venv\Scripts\Activate.ps1

# Install requirements
pip install -r requirements.txt
```

**Note:** If you get a PowerShell execution policy error, run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 2. API Keys

Create a `.env` file in the project directory:

```ini
GROK_API_KEY=gsk-...
OPENAI_API_KEY=sk-...  # optional if using --backend openai
```

### 3. Microphone Access

Ensure Windows has microphone permissions enabled:
- Settings → Privacy & Security → Microphone → Allow apps to access your microphone

## Usage

### Voice-Activated Mode (Default)

Start listening, speak, auto-stops on silence:

```powershell
python dictate_min.py
# or explicitly
python dictate_min.py --trigger voice
```

### Hotkey Mode (Numpad5)

**Hold to speak:**
```powershell
python dictate_min.py --trigger key --mode hold
```

**Toggle recording:**
```powershell
python dictate_min.py --trigger key --mode toggle
```

### Custom Hotkeys

```powershell
# Use spacebar
python dictate_min.py --trigger key --mode hold --hotkey space

# Use F9
python dictate_min.py --trigger key --mode toggle --hotkey f9
```

### Backend Selection

```powershell
# Groq (default, faster)
python dictate_min.py --backend grok

# OpenAI
python dictate_min.py --backend openai
```

### Print-Only Mode

Test transcription without typing:

```powershell
python dictate_min.py --print-only
```

## Advanced Features

### Adjustable Voice Detection

```powershell
# More sensitive (picks up quieter speech)
python dictate_min.py --silence-rms 0.01

# Less sensitive (requires louder speech)
python dictate_min.py --silence-rms 0.02

# Longer silence before stopping
python dictate_min.py --silence-stop-ms 1000
```

### Full Feature Script (dictate.py)

The `dictate.py` script provides additional features:

```powershell
# Basic usage
python dictate.py --backend grok --mode hold --hotkey numpad5

# Toggle mode
python dictate.py --backend grok --mode toggle --hotkey f9

# Daemon mode (background)
python dictate.py --daemon --backend grok --mode toggle --hotkey space
```

## Text Input Methods

The script tries multiple methods automatically:

1. **PyAutoGUI** (Primary) - Universal, works with most apps
2. **Pynput** (Fallback) - Direct keyboard control
3. **Win32 Clipboard** (Last resort) - Copies to clipboard
4. **Pyperclip** (Alternative) - Cross-platform clipboard

If typing fails, text is copied to clipboard for manual pasting (Ctrl+V).

## Troubleshooting

### Text Not Appearing

**Issue:** Script runs but text doesn't appear in application.

**Solutions:**
1. **Ensure the target window is focused** before and after speaking
2. Test with Notepad or VS Code first (most compatible)
3. Some apps block automated input (Windows security apps, elevated apps)
4. Try running your terminal/IDE as administrator if target app is elevated

### No Audio Detected

**Issue:** No transcription or "Nothing recorded" error.

**Solutions:**
1. Check Windows microphone permissions (Settings → Privacy → Microphone)
2. Select correct microphone in Windows Sound settings
3. Test microphone with Windows Voice Recorder
4. Adjust sensitivity: `--silence-rms 0.01` (more sensitive)

### API Errors

**Issue:** API key errors or connection issues.

**Solutions:**
1. Verify `.env` file exists with correct API keys
2. Check API key validity at provider's website
3. Ensure internet connection is active
4. Try different backend: `--backend openai` or `--backend grok`

### PyAutoGUI Issues

**Issue:** PyAutoGUI fails on multi-monitor setups or with scaling.

**Solutions:**
```powershell
# Install pillow for better screenshot support
pip install pillow

# Or force clipboard fallback
pip uninstall pyautogui
# Script will use clipboard automatically
```

## Windows Integration

### Create Desktop Shortcut

1. Right-click Desktop → New → Shortcut
2. Location: `C:\Windows\System32\cmd.exe /k "cd C:\src\whisper-dictation && .\venv\Scripts\activate && python dictate_min.py --trigger key --mode toggle"`
3. Name: "Whisper Dictate"
4. Right-click shortcut → Properties → Change Icon (optional)

### PowerShell Profile Alias

Add to your PowerShell profile (`$PROFILE`):

```powershell
function Start-Dictation {
    Push-Location C:\src\whisper-dictation
    .\venv\Scripts\Activate.ps1
    python dictate_min.py --trigger key --mode toggle
    Pop-Location
}

Set-Alias dictate Start-Dictation
```

Then use with: `dictate`

### AutoHotkey Integration

Create a `.ahk` script for global hotkey:

```autohotkey
#F12::  ; Win+F12 to start dictation
Run, powershell -Command "cd C:\src\whisper-dictation; .\venv\Scripts\activate; python dictate_min.py --trigger voice"
return
```

### Windows Task Scheduler (Background Service)

1. Open Task Scheduler
2. Create Task → Name: "Whisper Dictate Service"
3. Trigger: At log on
4. Action: Start a program
   - Program: `C:\src\whisper-dictation\venv\Scripts\python.exe`
   - Arguments: `dictate.py --daemon --backend grok --mode toggle --hotkey space`
   - Start in: `C:\src\whisper-dictation`
5. Settings: Allow task to run on demand

## Performance Tips

1. **Use Groq backend** - Faster than OpenAI for most use cases
2. **Toggle mode** - More responsive than hold mode
3. **Adjust thresholds** - Tune `--silence-rms` and `--silence-stop-ms` for your environment
4. **Close unused apps** - Better focus management and typing reliability

## Known Limitations

- Elevated applications (running as Administrator) may block text input
- Some games with anti-cheat may block automated input
- Windows Terminal may require special handling
- Remote desktop sessions may have input restrictions

## Requirements

- Windows 10/11
- Python 3.8 or higher
- Microphone with Windows permissions
- Internet connection for API access
- API key from Groq or OpenAI

## License

MIT - See [LICENSE](LICENSE) file for details

