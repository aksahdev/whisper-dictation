# whisper-dictate

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Minimal, reliable speech-to-text dictation. Defaults to Groq STT. Works on Linux (Wayland/X11) and Windows 11. Two ways to trigger dictation:
- Voice-activated one-shot (auto start/stop on speech/silence)
- Hotkey push-to-talk or toggle (default: numpad5)

Core script: `dictate_min.py`

## 🪟 Windows 11 Support

This branch (`windows-11-support`) is optimized for Windows 11! See:
- **[WINDOWS_SETUP.md](WINDOWS_SETUP.md)** - Step-by-step Windows setup guide
- **[README_WINDOWS.md](README_WINDOWS.md)** - Complete Windows usage documentation

**Quick start on Windows:**
1. Run `setup_windows.bat`
2. Create `.env` file with API keys
3. Double-click `run_dictate.bat`

---

## Linux Installation (Original)

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