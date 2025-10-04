#!/usr/bin/env python3
"""Test keyboard detection on Windows"""
import sys
try:
    from pynput import keyboard
except ImportError:
    print("ERROR: pynput not installed. Run: pip install pynput")
    sys.exit(1)

print("=" * 60)
print("Keyboard Test - Press any key to see if it's detected")
print("Press ESC to exit")
print("=" * 60)
print()

def on_press(key):
    try:
        print(f"Key pressed: {key} | char: {getattr(key, 'char', None)} | vk: {getattr(key, 'vk', None)}")
    except Exception as e:
        print(f"Key pressed: {key} (error: {e})")
    
    # Exit on ESC
    if key == keyboard.Key.esc:
        print("\nExiting...")
        return False

def on_release(key):
    try:
        print(f"Key released: {key}")
    except Exception as e:
        print(f"Key released: {key} (error: {e})")

print("Listening for keyboard events...")
print("Try pressing numpad5, space, F9, etc.")
print()

with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
    listener.join()

