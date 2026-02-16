# Configure OpenClaw with AISA's Unified API

Use [AISA](https://marketplace.aisa.one/) as your unified LLM backend for [OpenClaw](https://github.com/openclaw/openclaw). One API key gives you access to **50+ models** across 8 providers (OpenAI, Anthropic, Google, DeepSeek, xAI, Moonshot, Alibaba, ByteDance).

## Why AISA?

- **Cost-effective** - Unified billing, no need for multiple API subscriptions
- **Faster response** - Smart routing, auto-selects optimal nodes
- **One-click switch** - 50+ top models available anytime, no reconfiguration needed

## Getting Started

### Option 1: Fresh Install (No existing models)

> Please install OpenClaw by running the following command first and skip the model selection:

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

Run this single command to set everything up automatically:

```bash
curl -fsSL https://raw.githubusercontent.com/AIsa-team/Configuring-OpenClaw-with-AIsa-API/main/setup-aisa-llm.sh | bash
```

Then just:
1. Paste your AISA API Key when prompted (get one at https://marketplace.aisa.one/ - new users receive **$5 free credit**)
2. Press Enter through the prompts to accept defaults

That's it! Your OpenClaw is now configured with AISA LLM.

> **Tip:** You can also pass arguments non-interactively:
> ```bash
> curl -fsSL https://raw.githubusercontent.com/AIsa-team/Configuring-OpenClaw-with-AIsa-API/main/setup-aisa-llm.sh | bash -s -- --key sk-xxxx --model 1
> ```

### Option 2: Replace models in an existing OpenClaw bot

If you already have OpenClaw installed with other model providers, use the built-in guide to switch over. In your OpenClaw session, run:

```
use https://raw.githubusercontent.com/AIsa-team/Configuring-OpenClaw-with-AIsa-API/main/aisa-llm-guide.md to change my llm
```

Then just:
1. Paste your AISA API Key when prompted (get one at https://marketplace.aisa.one/ - new users receive **$5 free credit**)
2. Press Enter through the prompts to accept defaults

OpenClaw's AI assistant will read the guide and walk you through replacing your current model provider with AISA.

## What's in This Repo

This repository is self-contained with everything you need:

| File | Description |
|------|-------------|
| [`setup-aisa-llm.sh`](setup-aisa-llm.sh) | Automated setup script (used by Option 1) |
| [`aisa-llm-guide.md`](aisa-llm-guide.md) | Detailed configuration guide for AI assistants (used by Option 2) |

### Using the local files

If you've cloned this repo, you can also run the setup script locally:

```bash
./setup-aisa-llm.sh
```

Or point OpenClaw to the local guide:

```
use /path/to/Configuring-OpenClaw-with-AIsa-API/aisa-llm-guide.md to change my llm
```

## Available Models (48 total)

| Provider | Count | Featured Models |
|----------|-------|-----------------|
| OpenAI | 10 | gpt-5, gpt-5.2, gpt-4.1 |
| Anthropic | 10 | opus-4.1, sonnet-4.5, haiku-4.5 |
| Google | 5 | gemini-3-pro, 2.5-pro, 2.5-flash |
| DeepSeek | 4 | deepseek-r1, v3.1, v3 |
| xAI | 2 | grok-4, grok-3 |
| Moonshot | 2 | kimi-k2.5, kimi-k2-thinking |
| Alibaba | 15 | qwen3-max, qwen3-coder, vl-plus |

## Switching Models After Setup

Once configured, switch models in any OpenClaw session:

```
/model aisa/gpt-5
/model aisa/claude-opus-4-1-20250805
/model aisa/qwen3-max
/model aisa/deepseek-r1
```

## License

[MIT](LICENSE)
