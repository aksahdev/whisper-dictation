#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Minimal one-shot dictation script (Windows).

Flow:
  1) Start recording immediately
  2) Auto-stop on silence
  3) Transcribe (Groq default; OpenAI optional)
  4) Type result into focused window (Windows)

Supports voice-activated and hotkey-triggered modes.
"""
from __future__ import annotations

import argparse
import os
import queue
import sys
import tempfile
import time
import threading
from pathlib import Path

# Ensure third-party modules can be imported even when launched via a wrapper that
# doesn't activate the venv properly (e.g., editor-integrated runners).
def _ensure_local_sitepackages() -> None:
    base = Path(__file__).resolve().parent
    pyver = f"python{sys.version_info.major}.{sys.version_info.minor}"
    for env_name in ("venv", "whisper-env", ".venv"):
        sp = base / env_name / "lib" / pyver / "site-packages"
        if sp.exists():
            sp_str = str(sp)
            if sp_str not in sys.path:
                sys.path.insert(0, sp_str)

# Try imports; if they fail, add local venv site-packages and retry
try:
    import numpy as np  # type: ignore
    import sounddevice as sd  # type: ignore
    import soundfile as sf  # type: ignore
except Exception:
    _ensure_local_sitepackages()
    import numpy as np  # type: ignore
    import sounddevice as sd  # type: ignore
    import soundfile as sf  # type: ignore


try:
    from dotenv import load_dotenv
    load_dotenv()
except Exception:
    pass


def log(msg: str) -> None:
    print(f"[INFO] {msg}")


def warn(msg: str) -> None:
    print(f"[WARN] {msg}", file=sys.stderr)


def error(msg: str) -> None:
    print(f"[ERROR] {msg}", file=sys.stderr)


def rms_level(block: np.ndarray) -> float:
    if block.size == 0:
        return 0.0
    # int16 → float
    x = block.astype(np.float32) / 32768.0
    return float(np.sqrt(np.mean(x * x)))


def record_once(
    samplerate: int,
    silence_rms: float,
    min_speech_ms: int,
    silence_ms_to_stop: int,
    max_ms: int,
) -> Path | None:
    """Record from default mic. Start on voice, stop on silence or max duration.

    Returns path to temporary wav or None if nothing meaningful recorded.
    """
    q: queue.Queue[np.ndarray] = queue.Queue()
    started = False
    last_voice_ts = None
    t0 = time.monotonic()

    block_ms = 50  # 20 FPS
    frames_per_block = int(samplerate * (block_ms / 1000.0))

    def callback(indata, frames, ctime, status):  # noqa: N803
        if status:
            warn(str(status))
        q.put(indata.copy())

    with sd.InputStream(
        samplerate=samplerate,
        channels=1,
        dtype="int16",
        callback=callback,
        blocksize=frames_per_block,
    ):
        log("Listening... speak now.")
        collected: list[np.ndarray] = []
        speech_ms = 0
        while True:
            try:
                block = q.get(timeout=1.0)
            except queue.Empty:
                block = np.zeros((frames_per_block, 1), dtype=np.int16)

            level = rms_level(block)
            now = time.monotonic()

            if not started and level >= silence_rms:
                started = True
                last_voice_ts = now
                log("Voice detected → recording...")

            if started:
                collected.append(block)
                speech_ms += block_ms
                if level >= silence_rms:
                    last_voice_ts = now

                if last_voice_ts is not None and (now - last_voice_ts) * 1000.0 >= silence_ms_to_stop:
                    log("Silence detected → stopping.")
                    break

            if (now - t0) * 1000.0 >= max_ms:
                log("Max duration reached → stopping.")
                break

        if not collected or speech_ms < min_speech_ms:
            warn("No speech captured (or too short).")
            return None

        audio = np.concatenate(collected, axis=0)
        tmp = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
        sf.write(tmp.name, audio, samplerate)
        return Path(tmp.name)


class PushToTalkRecorder:
    """Simple push-to-talk recorder controlled by start()/stop()."""

    def __init__(self, samplerate: int = 16_000):
        self.samplerate = samplerate
        self._flag = False
        self._q: queue.Queue[np.ndarray] = queue.Queue()

        def callback(indata, frames, ctime, status):  # noqa: N803
            if status:
                warn(str(status))
            if self._flag:
                self._q.put(indata.copy())

        self._stream = sd.InputStream(
            samplerate=samplerate,
            channels=1,
            dtype="int16",
            callback=callback,
        )
        self._stream.start()

    def start(self) -> None:
        self._flag = True
        with self._q.mutex:
            self._q.queue.clear()

    def stop(self) -> Path | None:
        self._flag = False
        if self._q.empty():
            return None
        chunks: list[np.ndarray] = []
        while not self._q.empty():
            chunks.append(self._q.get())
        audio = np.concatenate(chunks, axis=0)
        tmp = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
        sf.write(tmp.name, audio, self.samplerate)
        return Path(tmp.name)

    def close(self) -> None:
        try:
            self._stream.stop()
            self._stream.close()
        except Exception:
            pass

def transcribe_groq(wav_path: Path, api_key: str | None) -> str:
    try:
        from groq import Groq  # type: ignore
    except Exception as e:
        raise RuntimeError("Missing 'groq' package. pip install groq") from e
    client = Groq(api_key=api_key) if api_key else Groq()
    with wav_path.open("rb") as f:
        resp = client.audio.transcriptions.create(
            file=(str(wav_path), f.read()),
            model="whisper-large-v3-turbo",
            response_format="verbose_json",
        )
    return resp.text.strip()


def transcribe_openai(wav_path: Path, api_key: str | None) -> str:
    try:
        import openai  # type: ignore
    except Exception as e:
        raise RuntimeError("Missing 'openai' package. pip install openai") from e
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY is required for --backend openai")
    client = openai.OpenAI(api_key=api_key)
    with wav_path.open("rb") as f:
        resp = client.audio.transcriptions.create(model="whisper-1", file=f)
    return resp.text.strip()




def type_text(text: str) -> bool:
    """Type text into focused window (Windows). Returns True on success."""
    
    # Try pyautogui first (cross-platform, works well on Windows)
    try:
        import pyautogui  # type: ignore
        pyautogui.PAUSE = 0.01
        pyautogui.write(text, interval=0.01)
        log("Typed text with pyautogui")
        return True
    except ImportError:
        pass
    except Exception as e:
        warn(f"pyautogui error: {e}")
    
    # Try pynput as fallback (already a dependency)
    try:
        from pynput.keyboard import Controller
        controller = Controller()
        controller.type(text)
        log("Typed text with pynput")
        return True
    except Exception as e:
        warn(f"pynput typing error: {e}")
    
    # Try Windows clipboard as last resort
    try:
        import win32clipboard  # type: ignore
        win32clipboard.OpenClipboard()
        win32clipboard.EmptyClipboard()
        win32clipboard.SetClipboardText(text, win32clipboard.CF_UNICODETEXT)
        win32clipboard.CloseClipboard()
        warn("Text copied to clipboard (pywin32). Paste with Ctrl+V.")
        return True
    except ImportError:
        pass
    except Exception as e:
        warn(f"Clipboard (pywin32) error: {e}")
    
    # Final fallback: use pyperclip
    try:
        import pyperclip  # type: ignore
        pyperclip.copy(text)
        warn("Text copied to clipboard (pyperclip). Paste with Ctrl+V.")
        return True
    except ImportError:
        pass
    except Exception as e:
        warn(f"pyperclip error: {e}")

    return False


def main(argv: list[str] | None = None) -> None:
    argv = argv or sys.argv[1:]

    p = argparse.ArgumentParser(description="Minimal whisper dictation (one-shot or hotkey)")
    p.add_argument("--backend", choices=["grok", "openai"], default="grok")
    p.add_argument("--samplerate", type=int, default=16_000)
    p.add_argument("--silence-rms", type=float, default=0.008, help="RMS threshold to detect speech (lower=more sensitive, try 0.005-0.02)")
    p.add_argument("--min-speech-ms", type=int, default=400, help="Minimum captured speech before accepting")
    p.add_argument("--silence-stop-ms", type=int, default=1500, help="Silence duration to stop after speech (1500ms = 1.5 seconds)")
    p.add_argument("--max-ms", type=int, default=20_000, help="Hard stop max recording duration")
    p.add_argument("--no-trailing-space", action="store_true", help="Do not add trailing space after text")
    p.add_argument("--print-only", action="store_true", help="Print text only (do not type)")
    # Trigger options
    p.add_argument("--trigger", choices=["voice", "key"], default="voice", help="Start by voice activity or via hotkey")
    p.add_argument("--mode", choices=["hold", "toggle"], default="hold", help="When --trigger=key: hold to talk or toggle start/stop")
    p.add_argument("--hotkey", default="numpad5", help="Hotkey for --trigger=key (default: numpad5)")

    args = p.parse_args(argv)

    # Keys - checks Windows environment variables automatically
    api_key_groq = os.getenv("GROK_API_KEY")
    api_key_openai = os.getenv("OPENAI_API_KEY")
    
    # Validate API key is present
    if args.backend == "grok" and not api_key_groq:
        error("GROK_API_KEY not found!")
        error("Run 'setup-api-key.bat' to configure your API key (one-time setup)")
        error("Or get your key from: https://console.groq.com/keys")
        sys.exit(1)
    elif args.backend == "openai" and not api_key_openai:
        error("OPENAI_API_KEY not found!")
        error("Run 'setup-api-key.bat' to configure your API key (one-time setup)")
        error("Or get your key from: https://platform.openai.com/api-keys")
        sys.exit(1)

    # Trigger
    text = ""
    if args.trigger == "voice":
        log("Voice mode active - will continuously listen for speech (async transcription)")
        log("Press Ctrl+C to exit")
        
        def process_transcription(wav_path, backend, api_key_g, api_key_o, print_only, no_trailing):
            """Process transcription in background thread"""
            try:
                if backend == "grok":
                    text = transcribe_groq(wav_path, api_key_g)
                else:
                    text = transcribe_openai(wav_path, api_key_o)
                
                if text:
                    if not no_trailing:
                        text += " "
                    
                    log(f"Transcribed: {text[:80]!r}")
                    
                    if print_only:
                        print(text)
                    else:
                        if not type_text(text):
                            error("Failed to inject text.")
                
            except Exception as e:
                error(f"Transcription error: {e}")
            finally:
                try:
                    wav_path.unlink(missing_ok=True)
                except Exception:
                    pass
        
        try:
            while True:
                wav = record_once(
                    samplerate=args.samplerate,
                    silence_rms=args.silence_rms,
                    min_speech_ms=args.min_speech_ms,
                    silence_ms_to_stop=args.silence_stop_ms,
                    max_ms=args.max_ms,
                )
                if wav is None:
                    warn("Nothing recorded. Waiting for next speech...")
                    continue
                
                # Start transcription in background thread
                log("Processing... (you can speak again)")
                thread = threading.Thread(
                    target=process_transcription,
                    args=(wav, args.backend, api_key_groq, api_key_openai, args.print_only, args.no_trailing_space),
                    daemon=True
                )
                thread.start()
                # Continue immediately to next recording without waiting
                
        except KeyboardInterrupt:
            print()
            log("Exiting voice mode...")
            sys.exit(0)
    else:
        # key trigger
        try:
            from pynput import keyboard  # type: ignore
        except Exception as e:
            error(f"Hotkey mode requires pynput: {e}")
            sys.exit(2)

        # Resolve hotkey (Windows-compatible)
        import platform
        special_vk = {
            "numpad5": 12 if platform.system() == "Windows" else 65437,  # VK_CLEAR on Windows
        }
        hotkey_key = None
        if args.hotkey.lower() in special_vk:
            hotkey_key = keyboard.KeyCode.from_vk(special_vk[args.hotkey.lower()])
            log(f"Using virtual key code {special_vk[args.hotkey.lower()]} for {args.hotkey}")
        else:
            hotkey_key = getattr(keyboard.Key, args.hotkey.lower(), None)
            if hotkey_key is None:
                try:
                    hotkey_key = keyboard.KeyCode.from_char(args.hotkey)
                except Exception:
                    error(f"Invalid hotkey: {args.hotkey}")
                    sys.exit(2)

        # Consider 'begin' (numpad center without numlock) as alias for numpad5
        begin_key = getattr(keyboard.Key, "begin", None)

        rec = PushToTalkRecorder(samplerate=args.samplerate)
        rec_active = {"v": False}

        def start_rec():
            if not rec_active["v"]:
                rec.start()
                rec_active["v"] = True
                log("Recording (hotkey)...")

        def process_hotkey_transcription(wav_path, backend, api_key_g, api_key_o, print_only, no_trailing):
            """Process hotkey transcription in background thread"""
            try:
                if backend == "grok":
                    t = transcribe_groq(wav_path, api_key_g)
                else:
                    t = transcribe_openai(wav_path, api_key_o)
                
                # Type or print the transcription
                if not no_trailing:
                    t += " "
                
                log(f"Transcribed: {t[:80]!r}")
                
                if not print_only:
                    if not type_text(t):
                        error("Failed to inject text.")
                else:
                    print(t)
            except Exception as e:
                error(f"Transcription error: {e}")
            finally:
                try:
                    wav_path.unlink(missing_ok=True)
                except Exception:
                    pass

        def stop_rec_and_transcribe():
            if rec_active["v"]:
                wav2 = rec.stop()
                rec_active["v"] = False
                if wav2 is None:
                    warn("Silent/empty recording.")
                    return
                
                # Start transcription in background thread
                log("Processing... (ready for next recording)")
                thread = threading.Thread(
                    target=process_hotkey_transcription,
                    args=(wav2, args.backend, api_key_groq, api_key_openai, args.print_only, args.no_trailing_space),
                    daemon=True
                )
                thread.start()
                # Return immediately without waiting for transcription

        def matches_hotkey(k) -> bool:
            # Direct comparison
            if k == hotkey_key:
                return True
            # Check virtual key code for special keys
            if hasattr(k, 'vk') and hasattr(hotkey_key, 'vk'):
                if k.vk is not None and hotkey_key.vk is not None:
                    if k.vk == hotkey_key.vk:
                        return True
            # Check for 'begin' key (numpad5 without numlock on some systems)
            if begin_key is not None and k == begin_key and args.hotkey.lower() == "numpad5":
                return True
            return False

        def on_press(k):
            try:
                # ESC to exit
                if k == keyboard.Key.esc:
                    log("ESC pressed - exiting...")
                    return False  # Stop listener
                
                if matches_hotkey(k):
                    if args.mode == "toggle":
                        if not rec_active["v"]:
                            start_rec()
                        else:
                            stop_rec_and_transcribe()
                    else:
                        start_rec()
            except Exception as e:
                warn(f"on_press error: {e}")

        def on_release(k):
            try:
                if args.mode == "hold" and matches_hotkey(k):
                    stop_rec_and_transcribe()
            except Exception as e:
                warn(f"on_release error: {e}")

        log(f"Hotkey mode active: {args.mode} on {args.hotkey.upper()}")
        log("Ready - press hotkey to dictate. Press ESC to exit.")
        
        try:
            listener = keyboard.Listener(on_press=on_press, on_release=on_release)
            listener.start()
            log("Keyboard listener started successfully")
        except Exception as e:
            error(f"Failed to start keyboard listener: {e}")
            error("Try running as Administrator or use --trigger voice instead")
            sys.exit(2)
        
        try:
            # Keep running until Ctrl+C
            listener.join()
        except KeyboardInterrupt:
            print()
            log("Exiting...")
        finally:
            try:
                listener.stop()
            except Exception:
                pass
            rec.close()
        
        # Exit after cleanup in hotkey mode
        sys.exit(0)

    # This code is now unreachable - voice mode has its own loop above
    # and hotkey mode exits with sys.exit(0)
    pass


if __name__ == "__main__":
    main()


