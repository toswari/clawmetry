# LMStudio Support Plan for ClawMetry

## Overview
Add LMStudio as a local LLM provider option alongside Ollama for cost optimization and local model tracking.

## Background
- LMStudio is a popular desktop app for running local LLMs with a built-in OpenAI-compatible API server
- Unlike Ollama's dedicated API, LMStudio exposes an OpenAI-compatible endpoint at `localhost:1234/v1`
- This makes detection and integration straightforward

## Implementation Plan

### 1. Provider Detection (`clawmetry/providers_pricing.py`) ✅ COMPLETED

Added LMStudio entry to `PROVIDER_MAP`:

```python
# Local LLM providers (zero cost)
"localhost:1234": {
    "name": "lmstudio",
    "input_per_1m": 0.0,
    "output_per_1m": 0.0,
},
"127.0.0.1:1234": {
    "name": "lmstudio",
    "input_per_1m": 0.0,
    "output_per_1m": 0.0,
},
```

### 2. Model Override Support ✅ COMPLETED

Added to `MODEL_OVERRIDES` for common LMStudio models:

```python
# LMStudio local models (zero cost)
("lmstudio", "llama"): (0.0, 0.0),
("lmstudio", "qwen"): (0.0, 0.0),
("lmstudio", "phi"): (0.0, 0.0),
("lmstudio", "mistral"): (0.0, 0.0),
("lmstudio", "deepseek"): (0.0, 0.0),
("lmstudio", "gemma"): (0.0, 0.0),
("lmstudio", "mixtral"): (0.0, 0.0),
("lmstudio", "codellama"): (0.0, 0.0),
("lmstudio", "neural"): (0.0, 0.0),
```

### 3. Auto-Detection Strategy ✅ COMPLETED

LMStudio uses OpenAI-compatible API format, detection implemented in `helpers/pricing.py`:

1. **Hostname detection**: Check for `localhost:1234` or `127.0.0.1:1234` in request URLs
2. **Prefix detection**: `lmstudio/` or `localhost:1234/` prefixes in model names
3. **Substring detection**: `lmstudio` or `localhost:1234` in model names for display

### 4. Configuration Support ✅ COMPLETED

Added to `clawmetry/config.py`:

```python
# Local LLM Providers
lmstudio_host: str = "localhost:1234"
lmstudio_enabled: bool = True
```

### 5. Testing Checklist ✅ COMPLETED

All tests pass (6/6):
- [x] Verify detection when LMStudio server is running on port 1234
- [x] Verify cost shows as $0.00 for LMStudio requests
- [x] Verify model names are captured correctly
- [x] Verify fallback when LMStudio is not running
- [x] Test with multiple concurrent local providers (Ollama + LMStudio)

## Similarities to Ollama

| Feature | Ollama | LMStudio |
|---------|--------|----------|
| API Format | Custom | OpenAI-compatible |
| Default Port | 11434 | 1234 |
| Cost | $0 | $0 |
| Detection | Hostname | Hostname + Port |
| Model List | `/api/tags` | `/v1/models` |

## Key Differences from Ollama

1. **API Compatibility**: LMStudio uses OpenAI API format, so it may be auto-detected as "openai" provider currently
2. **Port Flexibility**: LMStudio allows custom port configuration
3. **UI**: LMStudio has a desktop GUI for model management
4. **Model Loading**: Models must be explicitly loaded in LMStudio UI before API access

## Files Modified

1. ✅ `clawmetry/providers_pricing.py` - Added LMStudio to PROVIDER_MAP and MODEL_OVERRIDES
2. ✅ `clawmetry/config.py` - Added LMStudio configuration options
3. ✅ `helpers/pricing.py` - Added LMStudio detection in `_provider_from_model` and `_infer_provider_from_model`
4. ✅ `tests/test_api.py` - Added `TestLMStudioProvider` test class with 6 tests

## Future Enhancements

- [ ] UI badges for LMStudio provider in dashboard
- [ ] GPU memory tracking per model
- [ ] Model download/cache size reporting
- [ ] Temperature/top_p parameter tracking
- [ ] Prompt template visualization
- [ ] Health check endpoint for LMStudio availability
