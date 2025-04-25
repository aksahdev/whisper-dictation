# whisper-dictate

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Whisper speech-to-text dictation script, currently Linux only, supporting push-to-talk and toggle recording modes with configurable hotkey. Uses OpenAI or Groq APIs.

## Features
- Push-to-talk (hold) or toggle (press) recording modes
- Configurable hotkey (default: Right arrow)
- Backends:
  - OpenAI Whisper (`whisper-1` via OpenAI API)
  - Groq Grok STT (`whisper-large-v3-turbo` via Groq SDK)
- Reads API keys from `.env`
- Dependency list in `requirements.txt`

## System Dependencies

```bash
sudo apt install xdotool wtype
```

## Installation

```bash
git clone https://github.com/aksahdev/whisper-dictate.git
cd whisper-dictate
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Setup

Create a `.env` file in the project root:
```ini
OPENAI_API_KEY=sk-...
GROK_API_KEY=gsk-...
```

## Usage

```bash
python3 dictate.py -h            # show help menu
python3 dictate.py --backend openai
python3 dictate.py --backend grok --mode toggle --hotkey space
```

## Configuration

- `--backend`: `openai` or `grok`
- `--mode`: `hold` (default) or `toggle`
- `--hotkey`: key name (e.g., `right`, `space`, `f9`)

## Contributing

Contributions are welcome. Please fork and submit a pull request.

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

## TODO 

- [ ] Integrate local Whisper Models
- [ ] Add daemon mode
- [ ] Add more configuration options
- [ ] Add a GUI for non-power users
- [ ] Improve CLI UI
- [ ] Add script for setup
- [ ] Cross platform support (?)
- [ ] Refactor code for maintainability
- [ ] Add Streaming (live transcription) support