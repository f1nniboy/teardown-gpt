<h1 align="center">TearGPT</h1>
<p align="center"><i>ChatGPT & GPT-4 inside of <b>Teardown</b></i></p>

# Prerequisites
- [Deno runtime](https://docs.deno.com/runtime/manual/getting_started/installation)
- [OpenAI API key](https://platform.openai.com)

# Setup
Clone this repository into your local mods directory, located at `AppData/Local/Teardown/mods`. **Make sure to keep the directory name as `teargpt`, otherwise the mod won't work.**

# Running
## Backend
After you've installed Deno and signed up for OpenAI, copy `.env.example` to `.env` and fill in your OpenAI API key.

- **Windows**: double-click the `start.bat` in `scripts/`
- **Linux**: run `./scripts/start.sh`

# How does this work?
This mod abuses `loadfile()` to constantly load a temporary .lua file that the backend writes to, and the fact that changes to the savegame registry are saved almost immediately. Let's hope that Dennis doesn't change that behavior.