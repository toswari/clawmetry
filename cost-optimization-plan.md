# Cost Optimizer UI - LMStudio Integration Plan

## Overview
Add LMStudio as an alternative to Ollama in the Cost Optimizer modal, allowing users to install, run, and manage LMStudio for local LLM inference.

## Current State (from screenshot)
The Cost Optimizer modal currently shows:
- **Cost Overview** - Today and month projected costs
- **Your Hardware** - Detected hardware (Apple M4 Max, 64GB RAM, 16 cores, Apple Metal)
- **Recommended Local Models** - Via llmfit integration
- **Task Recommendations** - Suggestions for replacing cloud models with local alternatives
- **Quick Actions** - Buttons for "Install Ollama", "ollama serve", "Browse Models"

## Implementation Plan

### 1. Backend API Endpoints

#### New endpoints needed:
```
GET  /api/lmstudio/status      - Check if LMStudio is installed and running
POST /api/lmstudio/install     - Trigger LMStudio installation
POST /api/lmstudio/start       - Start LMStudio server
POST /api/lmstudio/stop        - Stop LMStudio server
GET  /api/lmstudio/models      - List available LMStudio models
```

#### Implementation in `routes/infra.py` or new `routes/lmstudio.py`:
```python
@bp_infra.route("/api/lmstudio/status")
def lmstudio_status():
    """Check LMStudio installation and server status."""
    # Check if LMStudio app exists (macOS)
    # Check if server is running on port 1234
    # Return { installed: bool, running: bool, models: [], port: 1234 }
```

### 2. Update Cost Optimizer Modal UI

#### Location: Find the modal template (search for "Cost Optimizer" in templates)

#### Add LMStudio Quick Actions:
```html
<!-- Update Quick Actions section -->
<div class="quick-actions">
  <!-- Existing Ollama actions -->
  <button class="action-btn primary" onclick="installOllama()">📦 Install Ollama</button>
  <button class="action-btn" onclick="toggleOllamaServe()">⚡ ollama serve</button>
  <button class="action-btn" onclick="browseModels()">🔍 Browse Models</button>
  
  <!-- New LMStudio actions -->
  <div style="margin-top:12px;border-top:1px solid var(--border-secondary);padding-top:12px;">
    <div style="font-size:11px;color:var(--text-muted);margin-bottom:8px;">LMStudio Alternative</div>
    <button class="action-btn" onclick="installLMStudio()">📦 Install LMStudio</button>
    <button class="action-btn" onclick="toggleLMStudio()">⚡ LMStudio Server</button>
    <button class="action-btn" onclick="browseLMStudioModels()">🔍 Browse Models</button>
  </div>
</div>
```

### 3. JavaScript Functions (app.js)

```javascript
// LMStudio status check
async function checkLMStudioStatus() {
  const resp = await fetch('/api/lmstudio/status');
  const data = await resp.json();
  return {
    installed: data.installed,
    running: data.running,
    models: data.models || [],
    port: data.port || 1234
  };
}

// Install LMStudio (macOS focused)
async function installLMStudio() {
  // macOS: Download from lmstudio.ai
  // Could use brew: brew install --cask lmstudio
  const confirm = window.confirm(
    'Install LMStudio from lmstudio.ai?\\n\\n' +
    'LMStudio provides a GUI for managing and running local LLMs.\\n' +
    'Requires ~500MB download.'
  );
  if (confirm) {
    window.open('https://lmstudio.ai', '_blank');
  }
}

// Toggle LMStudio server
async function toggleLMStudio() {
  const status = await checkLMStudioStatus();
  if (status.running) {
    await fetch('/api/lmstudio/stop', { method: 'POST' });
    showToast('LMStudio server stopped');
  } else {
    // LMStudio server is started from the GUI app
    showToast('Please start the LMStudio server from the LMStudio app');
  }
}

// Browse LMStudio models
async function browseLMStudioModels() {
  window.open('https://lmstudio.ai/models', '_blank');
}
```

### 4. Update Provider Detection

Already completed in `helpers/pricing.py`:
- ✅ `_provider_from_model()` detects `lmstudio/` prefix and `localhost:1234`
- ✅ `_infer_provider_from_model()` detects `lmstudio` substring

### 5. Update Cost Comparison Logic

In `routes/usage.py` or wherever cost comparisons are calculated:

```python
# Add LMStudio to local provider list
LOCAL_PROVIDERS = ["ollama", "lmstudio", "local/other"]

# When calculating savings, include LMStudio as $0.00 option
def calculate_savings(cloud_model, local_model, provider="lmstudio"):
    # LMStudio models are always $0.00
    return cloud_cost - 0.0
```

### 6. Update Hardware Detection

In `helpers/hardware.py`, ensure LMStudio-compatible hardware is detected:

```python
def detect_lmstudio_compatibility():
    """Check if hardware can run LMStudio efficiently."""
    # LMStudio supports:
    # - macOS with Apple Silicon (Metal)
    # - Windows with NVIDIA GPU (CUDA)
    # - Linux with NVIDIA GPU (CUDA)
    # - CPU fallback (slower)
    
    ram_gb = get_system_ram_gb()
    gpu = get_gpu_info()
    
    compatible = ram_gb >= 8  # Minimum 8GB RAM
    recommended = ram_gb >= 16  # Recommended 16GB+
    
    return {
        "compatible": compatible,
        "recommended": recommended,
        "max_model_size": estimate_max_model_size(ram_gb),
        "gpu_acceleration": gpu is not None
    }
```

### 7. Update Task Recommendations

Add LMStudio-specific recommendations:

```javascript
// In task recommendations rendering
const lmstudioRecommendations = [
  {
    task: "Cron: Morning Brief Telegram",
    current: "claude-sonnet-4-6",
    suggested: "qwen3:4b (LMStudio)",
    savings: "~$2-5/month",
    note: "Simple periodic checks don't need frontier models"
  },
  // ... more recommendations
];
```

### 8. Update Cost Optimizer Modal Footer

```html
<!-- Update footer to show both providers -->
<div class="optimizer-footer">
  <span>Auto-refreshing</span>
  <span>•</span>
  <span id="last-updated">Last updated: --:--:--</span>
  <span>•</span>
  <span id="llmfit-status">llmfit ✓</span>
  <span>•</span>
  <span id="metal-status">Metal backend ✓</span>
  <span>•</span>
  <span id="lmstudio-status">LMStudio: Not installed</span>
</div>
```

## Files to Modify

| File | Changes |
|------|---------|
| `routes/infra.py` or `routes/lmstudio.py` | Add LMStudio API endpoints |
| `clawmetry/templates/partials/budget-modal.html` | Add LMStudio UI to Cost Optimizer |
| `clawmetry/static/js/app.js` | Add LMStudio JS functions |
| `helpers/hardware.py` | Add LMStudio compatibility detection |
| `helpers/pricing.py` | ✅ Already updated |
| `clawmetry/providers_pricing.py` | ✅ Already updated |

## LMStudio vs Ollama Comparison

| Feature | Ollama | LMStudio |
|---------|--------|----------|
| Installation | CLI (`brew install ollama`) | GUI app (`.dmg` download) |
| Model Management | `ollama pull <model>` | GUI model browser |
| Server | `ollama serve` (auto) | Built-in server (port 1234) |
| API Format | Custom Ollama API | OpenAI-compatible |
| Model Format | Modelfile + GGUF | GGUF only |
| GPU Support | Metal, CUDA, ROCm | Metal, CUDA |
| Multi-model | Yes (concurrent) | Yes (load/unload) |
| Context Config | Via Modelfile | Via GUI settings |

## Installation Commands by Platform

### macOS
```bash
# Option 1: Homebrew (if available)
brew install --cask lmstudio

# Option 2: Direct download
open https://lmstudio.ai
```

### Windows
```powershell
# Download installer from lmstudio.ai
# Run LMStudio-Setup.exe
```

### Linux
```bash
# AppImage or .deb package
wget https://lmstudio.ai/download
chmod +x LMStudio.AppImage
./LMStudio.AppImage
```

## Next Steps

1. **Locate Cost Optimizer modal template** - Search dashboard.py for modal HTML
2. **Create API endpoints** - Add `/api/lmstudio/*` routes
3. **Add JavaScript functions** - Implement LMStudio actions in app.js
4. **Test integration** - Verify LMStudio detection and cost tracking
5. **Update documentation** - Add LMStudio to README and help docs

## Related Files Already Updated

- ✅ `clawmetry/providers_pricing.py` - LMStudio in PROVIDER_MAP
- ✅ `helpers/pricing.py` - LMStudio detection functions
- ✅ `clawmetry/config.py` - LMStudio configuration options
- ✅ `tests/test_api.py` - LMStudio test suite
- ✅ `README.md` - LMStudio in supported providers
- ✅ `CHANGELOG.md` - LMStudio feature announcement