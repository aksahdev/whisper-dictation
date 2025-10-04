# Whisper Dictate - Windows 11

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Fast, accurate speech-to-text dictation for Windows 11. Uses Groq or OpenAI Whisper API.

## ✨ Features

- 🎤 **Voice-activated mode** - Continuous listening, auto start/stop
- ⌨️ **Hotkey modes** - Hold or toggle with Numpad5 (or any key)
- ⚡ **Async transcription** - No waiting for API response
- 🔊 **Adjustable sensitivity** - Perfect for headsets and noisy environments
- 🚪 **ESC to exit** - Clean exit from any mode
- 🔄 **Continuous operation** - Runs indefinitely until you stop it

## 🚀 Installation (One Command!)

1. **Download and extract** this repository
2. **Double-click `SETUP.bat`**
3. Follow the wizard (installs binary, sets API key, creates shortcuts)
4. Done! ✅

The installer will:
- Install `whisper-dictate.exe` globally
- Add to Windows PATH
- Configure your API key (Groq or OpenAI)
- Create desktop shortcuts
- Optionally set up global hotkeys (Win+F12, Win+F11)

## 📖 Quick Start

After installation:

### Desktop Shortcuts (Easiest!)
Just double-click any shortcut on your desktop:
- **Whisper Dictate (Voice)** - Voice-activated
- **Whisper Dictate (Numpad5 Hold)** - Hold numpad5 to speak
- **Whisper Dictate (Numpad5 Toggle)** - Press numpad5 to start/stop

### Command Line
```powershell
# Voice-activated mode
whisper-dictate --trigger voice

# Hold numpad5 to speak
whisper-dictate --trigger key --mode hold --hotkey numpad5

# Toggle with space bar
whisper-dictate --trigger key --mode toggle --hotkey space

# Use OpenAI instead of Groq
whisper-dictate --trigger voice --backend openai
```

### Global Hotkeys (if AutoHotkey installed)
- **Win+F12**: Voice dictation
- **Win+F11**: Numpad5 hold mode

## ⚙️ Configuration

### Adjust Sensitivity
```powershell
# More sensitive (quiet speech)
whisper-dictate --trigger voice --silence-rms 0.005

# Less sensitive (noisy environment)
whisper-dictate --trigger voice --silence-rms 0.015
```

### Adjust Silence Timeout
```powershell
# Wait 2 seconds before stopping (for long sentences)
whisper-dictate --trigger voice --silence-stop-ms 2000

# Faster response (1 second)
whisper-dictate --trigger voice --silence-stop-ms 1000
```

## 🔑 API Keys

### First Time Setup
The installer will prompt you for your API key. Choose one:

- **Groq** (recommended - faster, cheaper): https://console.groq.com/keys
- **OpenAI**: https://platform.openai.com/api-keys

Your API key is saved as a Windows environment variable (permanent, secure).

### Manual Setup
If needed, you can set it manually:

```powershell
# PowerShell (permanent)
[Environment]::SetEnvironmentVariable('GROK_API_KEY', 'gsk-your-key-here', 'User')

# Or for OpenAI
[Environment]::SetEnvironmentVariable('OPENAI_API_KEY', 'sk-your-key-here', 'User')
```

## 🛠️ Advanced Usage

### Different Hotkeys
```powershell
whisper-dictate --trigger key --mode hold --hotkey f9
whisper-dictate --trigger key --mode toggle --hotkey space
```

### Print Only (Testing)
```powershell
whisper-dictate --trigger voice --print-only
```

### Combine Settings
```powershell
# Voice mode with custom sensitivity and timeout
whisper-dictate --trigger voice --silence-rms 0.007 --silence-stop-ms 1800 --backend grok
```

## 📁 Files

- `whisper-dictate.exe` - Standalone executable (~20MB)
- `SETUP.bat` - One-click installer
- `run_dictate.bat` - Quick launcher
- `dictate_min.py` - Source code

## 🐛 Troubleshooting

### Text not appearing
- Ensure target window is focused
- Some elevated apps (running as Admin) may block input
- Try running your terminal as Administrator

### API key errors
- Verify key is set: `echo %GROK_API_KEY%`
- Rerun SETUP.bat to reconfigure

### Microphone not working
- Check Windows Privacy → Microphone permissions
- Test with Windows Voice Recorder
- Adjust sensitivity with `--silence-rms`

### "whisper-dictate" not recognized
- Close and reopen terminal (PATH needs refresh)
- Or use desktop shortcuts (work immediately)

## 📝 License

MIT License - See [LICENSE](LICENSE) file

---

## Linux Installation (Original Branch)

## Features
- Groq backend by default (fast), OpenAI optional
- Wayland text typing via `ydotool`/`wtype`; X11 via `xdotool`
- One-shot voice mode or hotkey mode (hold/toggle)
- Numpad center without numlock is treated as `numpad5`

## Install

1) System packages
```bash
sudo apt install ydotool ydotoold wtype xdotool
```

2) Python deps
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

3) API keys in `.env`
```ini
GROK_API_KEY=gsk-...
OPENAI_API_KEY=sk-...  # optional if using --backend openai
```

## Usage

Voice (default):
```bash
python3 dictate_min.py
# or explicitly
python3 dictate_min.py --trigger voice
```

Hotkey (numpad5, hold):
```bash
python3 dictate_min.py --trigger key --mode hold
```

Hotkey (numpad5, toggle):
```bash
python3 dictate_min.py --trigger key --mode toggle
```

Custom key (examples):
```bash
python3 dictate_min.py --trigger key --mode hold --hotkey space
python3 dictate_min.py --trigger key --mode toggle --hotkey f9
```

Print-only (no typing):
```bash
python3 dictate_min.py --print-only
```

Backend selection:
```bash
python3 dictate_min.py --backend openai
# default is --backend grok
```

## Hyprland

Add a bind (toggle example):
```bash
bind = SUPER, F12, exec, sh -lc 'cd /home/$USER/src/pyscripts/whisper-dictate && python3 dictate_min.py --trigger key --mode toggle'
exec-once = ydotoold
```

## Troubleshooting

- Ensure `ydotoold` is running for Wayland typing:
```bash
pgrep ydotoold || ydotoold &
```
- Focus the target window before/after running
- If typing fails, use `--print-only` to confirm STT and check `TROUBLESHOOTING.md`

## License

MIT