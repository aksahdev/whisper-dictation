# Troubleshooting Guide

## Text Not Appearing in Other Applications

If the script shows successful typing but text doesn't appear in other editors, try these solutions:

### 1. Focus Issue (Most Common)
Make sure the target application (text editor, browser, etc.) is **actively focused** before/after triggering dictation. The text input tools require the target window to have focus.

### 2. Try Different Tools
The script tries tools in this order for Wayland:
1. `wtype` (now prioritized - usually most reliable)
2. `ydotool` (fallback)
3. `pyautogui` (final fallback)

You can force a specific tool by modifying the script or testing manually:
```bash
# Test wtype directly
wtype "test text"

# Test ydotool directly (ensure daemon is running)
ydotoold &
ydotool type "test text"

# Test xdotool (for X11)
xdotool type "test text"
```

### 3. Application-Specific Issues
Some applications have restrictions:
- **Firefox/Chrome**: May block automated input in certain fields
- **Terminal applications**: Some terminals don't accept simulated input
- **Flatpak/Snap apps**: May have additional sandboxing restrictions

### 4. Wayland Security
Some Wayland compositors restrict input simulation for security. Try:
```bash
# Run ydotoold with different permissions
sudo ydotoold
# Then test: ydotool type "test"
```

### 5. Alternative: Use Clipboard
If typing doesn't work, you could modify the script to copy text to clipboard:
```bash
echo "transcribed text" | wl-copy  # Wayland
echo "transcribed text" | xclip -selection clipboard  # X11
```

## Daemon Mode Usage

### Start Daemon
```bash
# Manual start
nohup python3 dictate.py --daemon --backend grok --mode toggle --hotkey space --log-file ~/whisper-daemon.log > /dev/null 2>&1 &

# Or use systemd (after running setup_daemon.sh)
systemctl --user start whisper-dictate@$USER.service
```

### Check Daemon Status
```bash
# Check if running
ps aux | grep dictate

# Check logs
tail -f ~/whisper-daemon.log

# Or with systemd
journalctl --user -u whisper-dictate@$USER.service -f
```

### Stop Daemon
```bash
# Find and kill process
pkill -f dictate.py

# Or with systemd
systemctl --user stop whisper-dictate@$USER.service
```

### Auto-start on Login
```bash
systemctl --user enable whisper-dictate@$USER.service
```

## Testing Recommendations

1. **Test in simple applications first**: Try gedit, kate, or a basic text editor
2. **Test focus timing**: Make sure you focus the target app AFTER the transcription completes
3. **Check environment**: Verify your session type with `echo $XDG_SESSION_TYPE`
4. **Test tools manually**: Use the commands above to test each typing tool individually

## Common Issues

- **"No working tool found"**: Install required packages with `./install.sh`
- **Xlib warnings**: These are harmless when using pynput on Wayland
- **Daemon exits immediately**: Check the log file for error messages
- **No transcription**: Verify API keys are set in `.env` file
- **Poor recognition**: Check microphone levels and background noise