#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# See LICENSE for details.
"""Whisper speech-to-text dictation script for Linux.

Features
--------
• Push-to-talk (hold) or toggle recording (press) modes.
• Configurable hotkey (default: numpad5 via --hotkey).
• Backends: OpenAI Whisper (`whisper-1`) & Groq STT.

Install deps
------------
    sudo apt install xdotool wtype
    pip install -r requirements.txt

Usage
-----
    # Add API keys to .env before running
    python3 dictate.py --backend grok
    python3 dictate.py --backend openai --mode toggle --hotkey space
"""
from __future__ import annotations

import argparse
import os
import queue
import subprocess
import sys
import tempfile
import signal
import logging
from pathlib import Path

import numpy as np  # type: ignore
import sounddevice as sd  # type: ignore
import soundfile as sf  # type: ignore
from pynput import keyboard  # type: ignore

try:
    import openai  # type: ignore
except ImportError:
    openai = None  # defer error until used

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

# ------------------------------------------------------------------------
# Typing helpers
# ------------------------------------------------------------------------

def _type_text(text: str) -> None:
    """Type *text* into the active window using available tools."""
    import time
    
    # Small delay to ensure the window is ready to receive input
    time.sleep(0.1)
    
    session_type = os.environ.get("XDG_SESSION_TYPE", "").lower()
    wayland_display = os.environ.get("WAYLAND_DISPLAY")
    x11_display = os.environ.get("DISPLAY")
    
    print(f"[DEBUG] Session type: {session_type}, Wayland: {wayland_display}, X11: {x11_display}", file=sys.stderr)
    
    # Wayland environment - try Wayland-specific tools first
    if session_type == "wayland" or wayland_display:
        # Try wtype first (often more reliable than ydotool)
        if subprocess.run(["which", "wtype"], capture_output=True).returncode == 0:
            try:
                result = subprocess.run(["wtype", text], 
                                      capture_output=True, text=True, timeout=5)
                if result.returncode != 0:
                    print(f"[DEBUG] wtype failed: {result.stderr}", file=sys.stderr)
                else:
                    print(f"[DEBUG] Successfully typed with wtype: {text[:50]}...", file=sys.stderr)
                    return
            except subprocess.TimeoutExpired:
                print("[ERROR] wtype timed out", file=sys.stderr)
        
        # Fallback to ydotool for Wayland
        if subprocess.run(["which", "ydotool"], capture_output=True).returncode == 0:
            try:
                # Check if ydotoold is running, if not start it
                daemon_check = subprocess.run(["pgrep", "ydotoold"], capture_output=True)
                if daemon_check.returncode != 0:
                    print("[INFO] Starting ydotool daemon...", file=sys.stderr)
                    subprocess.Popen(["ydotoold"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    time.sleep(0.5)  # Give daemon time to start
                
                result = subprocess.run(["ydotool", "type", text], 
                                      capture_output=True, text=True, timeout=5)
                if result.returncode != 0:
                    print(f"[DEBUG] ydotool failed: {result.stderr}", file=sys.stderr)
                else:
                    print(f"[DEBUG] Successfully typed with ydotool: {text[:50]}...", file=sys.stderr)
                    return
            except subprocess.TimeoutExpired:
                print("[ERROR] ydotool timed out", file=sys.stderr)
            except Exception as e:
                print(f"[DEBUG] ydotool error: {e}", file=sys.stderr)

    # X11 environment or fallback
    if session_type == "x11" or x11_display or not (session_type == "wayland" or wayland_display):
        if subprocess.run(["which", "xdotool"], capture_output=True).returncode == 0:
            try:
                result = subprocess.run(["xdotool", "type", "--delay", "10", text], 
                                      capture_output=True, text=True, timeout=5)
                if result.returncode != 0:
                    print(f"[DEBUG] xdotool failed: {result.stderr}", file=sys.stderr)
                else:
                    print(f"[DEBUG] Successfully typed with xdotool: {text[:50]}...", file=sys.stderr)
                    return
            except subprocess.TimeoutExpired:
                print("[ERROR] xdotool timed out", file=sys.stderr)

    # Python fallback (works on both X11 and Wayland in some cases)
    try:
        import pyautogui  # type: ignore
        pyautogui.typewrite(text, interval=0.01)
        print(f"[DEBUG] Successfully typed with pyautogui: {text[:50]}...", file=sys.stderr)
        return
    except ImportError:
        pass
    
    print("[ERROR] No working tool found to emit keystrokes. Please install:", file=sys.stderr)
    print("  - For Wayland: ydotool + ydotoold, or wtype", file=sys.stderr)
    print("  - For X11: xdotool", file=sys.stderr)
    print("  - Universal: pip install pyautogui", file=sys.stderr)

# ---------------------------------------------------------------------------
# Recorder class
# ---------------------------------------------------------------------------

class PushToTalkRecorder:
    def __init__(self, samplerate: int = 16_000):
        self.samplerate = samplerate
        self._flag = False
        self._q: queue.Queue[np.ndarray] = queue.Queue()

        self._stream = sd.InputStream(
            samplerate=samplerate,
            channels=1,
            dtype="int16",
            callback=self._callback,
        )
        self._stream.start()

    def _callback(self, indata, frames, time, status):  # noqa: N803
        if status:
            print(f"[Recorder] {status}", file=sys.stderr)
        if self._flag:
            self._q.put(indata.copy())

    # Control
    def start(self):
        self._flag = True
        with self._q.mutex:
            self._q.queue.clear()

    def stop(self) -> Path | None:
        self._flag = False
        if self._q.empty():
            return None
        chunks = []
        while not self._q.empty():
            chunks.append(self._q.get())
        audio = np.concatenate(chunks, axis=0)
        tmp = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
        sf.write(tmp.name, audio, self.samplerate)
        return Path(tmp.name)

    def close(self):
        self._stream.stop()
        self._stream.close()

# ---------------------------------------------------------------------------
# Transcribers
# ---------------------------------------------------------------------------

def transcribe_openai(wav_path: Path, api_key: str, model: str = "whisper-1") -> str:
    if openai is None:
        raise RuntimeError("openai package missing – pip install openai")

    client = openai.OpenAI(api_key=api_key)
    with wav_path.open("rb") as f:
        resp = client.audio.transcriptions.create(model=model, file=f)
    return resp.text.strip()


def transcribe_grok(wav_path: Path, api_key: str) -> str:
    try:
        from groq import Groq
    except ImportError:
        raise RuntimeError("groq package missing – pip install groq")
    # init client (use provided key or env var)
    client = Groq(api_key=api_key) if api_key else Groq()
    # read audio and send to Grok STT
    with wav_path.open("rb") as f:
        resp = client.audio.transcriptions.create(
            file=(str(wav_path), f.read()),
            model="whisper-large-v3-turbo",
            response_format="verbose_json",
        )
    # return the transcribed text
    return resp.text.strip()


TRANSCRIBERS = {
    "openai": transcribe_openai,
    "grok": transcribe_grok,
}

# ---------------------------------------------------------------------------
# Daemon functionality
# ---------------------------------------------------------------------------

def setup_daemon(log_file=None):
    """Setup daemon mode - configure logging and signal handling"""
    import os
    import sys
    
    # Setup logging
    if log_file:
        log_path = os.path.expanduser(log_file)
    else:
        log_path = os.path.expanduser("~/.local/share/whisper-dictate.log")
    
    # Ensure log directory exists
    os.makedirs(os.path.dirname(log_path), exist_ok=True)
    
    # Setup logging configuration
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_path),
        ]
    )
    
    # Handle signals for clean shutdown
    def signal_handler(signum, frame):
        logging.info(f"Received signal {signum}, shutting down...")
        sys.exit(0)
    
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    logging.info(f"Daemon mode started, logging to {log_path}")
    print(f"[INFO] Daemon mode active. Logging to: {log_path}")
    print(f"[INFO] Process running in background (PID: {os.getpid()})")

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> None:
    argv = argv or sys.argv[1:]
    p = argparse.ArgumentParser(
        description="Push-to-talk dictation (reads API keys from .env).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Examples:
  python3 dictate.py --backend grok --mode hold --hotkey numpad5
  python3 dictate.py --backend openai --mode toggle --hotkey f9"""
    )
    p.add_argument(
        "--backend",
        choices=TRANSCRIBERS.keys(),
        default="grok",
        help="Speech-to-text backend to use: 'openai' or 'grok' (default: grok)",
    )
    p.add_argument("--hotkey", default="numpad5", help="Key to use for recording (default: numpad5)")
    p.add_argument("--mode", choices=["hold","toggle"], default="hold",
                   help="Recording mode: 'hold' to push-to-talk, 'toggle' to start/stop on key press (default: hold)")
    p.add_argument("--daemon", action="store_true", help="Run as daemon in background")
    p.add_argument("--log-file", default=None, help="Log file path (for daemon mode)")
    # support `help` command
    if argv and argv[0].lower() == "help":
        p.print_help()
        sys.exit(0)
    args = p.parse_args(argv)

    # Setup daemon mode if requested
    if args.daemon:
        setup_daemon(args.log_file)

    # Map special hotkey names to virtual keycodes
    special_vk = {
        "numpad5": 65437,
    }

    # Load API key from environment variables exclusively
    if args.backend == "openai":
        api_key = os.getenv("OPENAI_API_KEY")
    elif args.backend == "grok":
        api_key = os.getenv("GROK_API_KEY")
    else:
        api_key = None
    if not api_key:
        p.error(f"Missing API key for backend {args.backend}; please set in .env file.")

    transcriber = TRANSCRIBERS[args.backend]
    rec = PushToTalkRecorder()
    mode = args.mode
    # Display selected options
    print(f"[INFO] Backend: {args.backend}, Mode: {mode}, Hotkey: {args.hotkey.upper()}")
    if mode == "hold":
        print(f"[INFO] Hold {args.hotkey.upper()} to speak.  Ctrl+C to exit.")
    else:
        print(f"[INFO] Press {args.hotkey.upper()} to toggle recording.  Ctrl+C to exit.")

    hotkey_key = None
    if args.hotkey.lower() in special_vk:
        hotkey_key = keyboard.KeyCode.from_vk(special_vk[args.hotkey.lower()])
    else:
        hotkey_key = getattr(keyboard.Key, args.hotkey.lower(), None)
        if hotkey_key is None:
            hotkey_key = keyboard.KeyCode.from_char(args.hotkey)

    def on_press(key):
        # Show current options if '?' is pressed
        if hasattr(key, 'char') and key.char == '?':
            print(f"[INFO] Backend: {args.backend}, Mode: {mode}, Hotkey: {args.hotkey.upper()}")
            return
        # Toggle recording on hotkey press
        if key == hotkey_key:
            if mode == "toggle":
                if not rec._flag:
                    rec.start()
                    print("[INFO] Recording started... press again to stop.")
                else:
                    wav = rec.stop()
                    if wav is None:
                        print("[WARN] Silent recording – ignored.")
                    else:
                        try:
                            text = transcriber(wav, api_key)  # type: ignore[arg-type]
                            print("[DEBUG]", text)
                            _type_text(text + " ")
                        except Exception as e:
                            print("[ERROR]", e)
                        finally:
                            wav.unlink(missing_ok=True)
            else:
                # hold mode: start recording on press
                if not rec._flag:
                    rec.start()
                    print("[INFO] Recording... (release to stop)")

    # Setup listener based on mode
    if mode == "hold":
        def on_release(key):
            if key == hotkey_key and rec._flag:
                wav = rec.stop()
                if wav is None:
                    print("[WARN] Silent recording – ignored.")
                else:
                    try:
                        text = transcriber(wav, api_key)  # type: ignore[arg-type]
                        print("[DEBUG]", text)
                        _type_text(text + " ")
                    except Exception as e:
                        print("[ERROR]", e)
                    finally:
                        wav.unlink(missing_ok=True)
        listener = keyboard.Listener(on_press=on_press, on_release=on_release)
    else:
        listener = keyboard.Listener(on_press=on_press)

    with listener as listener:
        try:
            listener.join()
        except KeyboardInterrupt:
            print("\n[INFO] Exiting.")
        finally:
            rec.close()

if __name__ == "__main__":
    main()
