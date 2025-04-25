# whisper-dictate

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Universal speech-to-text dictation script for Linux supporting push-to-talk and toggle recording modes with configurable hotkey.

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
git clone https://github.com/<your-org>/whisper-dictate.git
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
python3 dictate.py help            # show colored help menu
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
