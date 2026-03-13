# ddev-litellm

A [DDEV](https://ddev.com) add-on that runs a [LiteLLM](https://www.litellm.ai/) proxy as a DDEV service, enabling local AI model testing with Drupal's [`ai_provider_litellm`](https://www.drupal.org/project/ai_provider_litellm) module.

## Features

- LiteLLM proxy service accessible inside DDEV at `http://ddev-<project>-litellm:4000`
- Pre-configured to connect to [Ollama](https://ollama.ai) running on the host machine
- Optional vLLM / HuggingFace endpoint support
- Auto-configures the Drupal `ai_provider_litellm.settings.host` on each `ddev start`
- Custom `ddev litellm` and `ddev litellm-models` commands

## Requirements

- DDEV ≥ 1.24.10
- [Ollama](https://ollama.ai) installed on your host machine (for Ollama backend)
- At least one Ollama model pulled: `ollama pull llama3.2`

## Installation

```shell
ddev add-on get credevator/ddev-litellm
ddev restart
```

## Usage

### Service URLs

| Context | URL |
|---|---|
| Drupal web container | `http://ddev-<project>-litellm:4000` |
| Host browser | `https://<project>.ddev.site:4001` |

### Commands

```shell
ddev litellm              # Show service status
ddev litellm open         # Open LiteLLM UI in browser
ddev litellm logs         # View service logs
ddev litellm-models       # List available models
```

### Configuring Models

Edit `.ddev/litellm_config.yaml` to add or modify model backends, then run `ddev restart`.

**Ollama** (default, connects to host machine port 11434):
```yaml
- model_name: ollama/llama3.2
  litellm_params:
    model: ollama/llama3.2
    api_base: http://host.docker.internal:11434
```

**vLLM / HuggingFace** (uncomment in `litellm_config.yaml` and set `VLLM_API_BASE`):
```yaml
# In .ddev/config.yaml:
# web_environment:
#   - VLLM_API_BASE=http://host.docker.internal:8000
```

### Configuring Drupal

The add-on automatically sets `ai_provider_litellm.settings.host` on each `ddev start`.

You still need to configure the API key manually:
1. Go to **Configuration → Key** (`/admin/config/system/keys`)
2. Add a key named `litellm_key` with value `sk-ddev-litellm` (or your custom key)
3. Go to **Configuration → AI → Providers** (`/admin/config/ai/providers/litellm`)
4. Select your key under **API Key**

### Overriding the Master Key

The default key is `sk-ddev-litellm`. To change it, add to `.ddev/config.yaml`:

```yaml
web_environment:
  - LITELLM_MASTER_KEY=sk-your-custom-key
```

Then update the Drupal Key module entry to match.

## Troubleshooting

**LiteLLM takes a while to start** — the image is ~2GB and has a 90-second startup window. Check with `ddev litellm logs` if it fails to become healthy.

**Cannot reach Ollama** — ensure Ollama is running on the host (`ollama serve`) and the model is pulled (`ollama pull llama3.2`).

**Port 4000 or 4001 conflict** — edit `HTTP_EXPOSE` / `HTTPS_EXPOSE` in `.ddev/docker-compose.litellm.yaml`.

**Linux users** — `host.docker.internal` is injected via `extra_hosts: host.docker.internal:host-gateway` in the compose file. This is handled automatically.

## Uninstalling

```shell
ddev add-on remove ddev-litellm
ddev restart
```

Note: `.ddev/litellm_config.yaml` is preserved on removal. Delete it manually if no longer needed.

## License

Apache 2.0
