# Hyprland Setup Guide for Whisper Dictate

This guide provides multiple ways to integrate whisper-dictate with Hyprland for optimal performance.

## Quick Start (Recommended)

### Method 1: Direct Hyprland Keybind (Best Performance)

Add this to your `~/.config/hypr/hyprland.conf`:

```bash
# Whisper Dictate - Toggle Mode
bind = SUPER, F12, exec, /home/osiris/src/pyscripts/whisper-dictate/run_dictate_fixed.sh --backend grok --mode toggle --hotkey space

# Alternative: Hold Mode
bind = SUPER, F11, exec, /home/osiris/src/pyscripts/whisper-dictate/run_dictate_fixed.sh --backend grok --mode hold --hotkey space
```

**Advantages:**
- No background daemon needed
- Direct integration with Hyprland
- Better resource usage
- More reliable

### Method 2: Background Daemon with Global Hotkey

1. **Start the daemon:**
```bash
./run_dictate_fixed.sh --daemon --backend grok --mode toggle --hotkey space
```

2. **Or use systemd service:**
```bash
# Copy the enhanced service file
cp whisper-dictate-fixed.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user start whisper-dictate-fixed.service
systemctl --user enable whisper-dictate-fixed.service  # Auto-start on login
```

## Troubleshooting

### Issue 1: Keypress Not Detected

**Symptoms:** Script runs but doesn't respond to keypresses

**Solutions:**
1. **Use Hyprland binds (Method 1)** - Most reliable
2. **Check keyboard permissions:**
   ```bash
   # Ensure you're in the input group
   groups | grep input
   
   # If not in input group:
   sudo usermod -a -G input $USER
   # Then logout/login
   ```

3. **Test keyboard detection:**
   ```bash
   ./run_dictate_fixed.sh --test-keyboard
   ```

### Issue 2: Text Not Appearing in Other Apps

**Symptoms:** Script shows transcription but text doesn't appear in editors

**Solutions:**
1. **Ensure ydotoold is running:**
   ```bash
   pgrep ydotoold || sudo ydotoold &
   ```

2. **Test text injection:**
   ```bash
   ./run_dictate_fixed.sh --test-typing
   ```

3. **Focus the target application** before/after triggering dictation

4. **Try different text injection tools manually:**
   ```bash
   # Test ydotool
   ydotool type "test text"
   
   # Test wtype
   wtype "test text"
   ```

### Issue 3: Background Daemon Issues

**Symptoms:** Daemon starts but doesn't work properly

**Solutions:**
1. **Check daemon logs:**
   ```bash
   journalctl --user -u whisper-dictate-fixed.service -f
   ```

2. **Verify environment variables:**
   ```bash
   systemctl --user show-environment
   ```

3. **Manual daemon test:**
   ```bash
   # Test daemon mode manually
   ./run_dictate_fixed.sh --daemon --backend grok --mode toggle --hotkey space --log-file ~/whisper-test.log
   
   # Check logs
   tail -f ~/whisper-test.log
   ```

## Advanced Configuration

### Custom Hyprland Integration

You can create more sophisticated integrations:

```bash
# In hyprland.conf

# Different modes for different situations
bind = SUPER, F10, exec, /home/osiris/src/pyscripts/whisper-dictate/run_dictate_fixed.sh --backend grok --mode toggle
bind = SUPER SHIFT, F10, exec, /home/osiris/src/pyscripts/whisper-dictate/run_dictate_fixed.sh --backend openai --mode toggle
bind = SUPER, F9, exec, /home/osiris/src/pyscripts/whisper-dictate/run_dictate_fixed.sh --backend grok --mode hold

# Quick test binds
bind = SUPER ALT, T, exec, /home/osiris/src/pyscripts/whisper-dictate/run_dictate_fixed.sh --test-typing
bind = SUPER ALT, K, exec, /home/osiris/src/pyscripts/whisper-dictate/run_dictate_fixed.sh --test-keyboard
```

### Environment Variables for Daemon

If using systemd service, you may need to adjust environment variables in the service file:

```ini
# In whisper-dictate-fixed.service
Environment="DISPLAY=:1"  # Adjust if different
Environment="WAYLAND_DISPLAY=wayland-1"  # Adjust if different
Environment="XDG_RUNTIME_DIR=/run/user/1000"  # Adjust user ID if different
```

### Performance Optimization

1. **Use Grok backend** (faster than OpenAI for most use cases)
2. **Use toggle mode** instead of hold mode for better responsiveness
3. **Use Hyprland binds** instead of global hotkeys when possible

## Verification Commands

```bash
# Check all components
./run_dictate_fixed.sh --test-keyboard  # Test keyboard detection
./run_dictate_fixed.sh --test-typing    # Test text injection
./run_dictate_fixed.sh --help           # Show all options

# Check system status
echo "Session: $XDG_SESSION_TYPE"
echo "Wayland: $WAYLAND_DISPLAY" 
echo "X11: $DISPLAY"
pgrep ydotoold && echo "ydotoold: running" || echo "ydotoold: not running"
groups | grep -q input && echo "input group: yes" || echo "input group: no"
```

## Recommended Setup

For the best Hyprland experience:

1. **Use Method 1 (Direct Hyprland Keybind)**
2. **Use toggle mode** for better control
3. **Use Grok backend** for speed
4. **Keep ydotoold running** in the background

Example final configuration:
```bash
# In hyprland.conf
bind = SUPER, F12, exec, /home/osiris/src/pyscripts/whisper-dictate/run_dictate_fixed.sh --backend grok --mode toggle

# Optional: Auto-start ydotoold
exec-once = ydotoold
```

This setup provides the most reliable and performant whisper-dictate experience on Hyprland.
