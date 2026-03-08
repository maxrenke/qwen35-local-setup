# Qwen3.5 Local AI -- Setup & Usage Guide
Run Qwen3.5 fully locally on your RTX 4070 SUPER via WSL2, and use it as
the backend for Claude Code and OpenAI Codex CLI -- free, private, no API costs.
---
## Your Hardware
| Component | Spec |
|-----------|------|
| CPU | AMD Ryzen 7 5800XT (8c / 16t) |
| RAM | 32GB DDR4 @ 3200MHz |
| GPU | NVIDIA RTX 4070 SUPER -- 12GB VRAM |
| OS | Windows 10 Pro + WSL2 (Ubuntu 24) |
---
## Available Models
Three models are available -- choose based on speed vs quality tradeoff:
| Flag | Model | Size | VRAM | Speed | Quality |
|------|-------|------|------|-------|---------|
| `-Model 9B-Q4` | Qwen3.5-9B Q4 | 6.5GB | fully in VRAM | ~63 tok/s | Good -- fast everyday coding |
| `-Model 9B-Q6` | Qwen3.5-9B Q6 | 9GB | fully in VRAM | ~50 tok/s | Better -- near full precision |
| `-Model 35B` | Qwen3.5-35B-A3B Q3 | 17GB | VRAM + RAM | ~25-40 tok/s | Best -- strongest reasoning |
**Which to use?**
- Daily coding, fast iteration --> `9B-Q4` (default)
- Better output quality, still fast --> `9B-Q6`
- Hard problems, architecture decisions, complex debugging --> `35B`
- The 35B is MoE (Mixture of Experts) so only 3B parameters are active at once,
  meaning the RAM spillover penalty is much smaller than a dense 35B model.
---
## Scripts in This Folder
| Script | Purpose | Run once? |
|--------|---------|-----------|
| `Fix-WslMemory.ps1` | Gives WSL 24GB RAM (required to compile llama.cpp) | Done |
| `Install-ClaudeCodex.ps1` | Installs Claude Code + Codex CLI via npm | Done |
| `Start-WslServer.ps1` | Starts llama-server in WSL | Every session |
| `Start-ClaudeCode.ps1` | Launches Claude Code (local or cloud) | Every session |
| `Start-Codex.ps1` | Launches Codex CLI (local or cloud) | Every session |
| `Start-ChatUI.ps1` | Launches Open WebUI browser chat | Every session |
| `update-all.sh` | Updates everything in WSL (run in WSL) | Weekly |
---
## Daily Workflow
### Step 1 -- Start the model server (WSL)
Open a WSL terminal:
```bash
cd ~/qwen3.5
./serve_qwen35_9b.sh          # default (9B Q4)
```
Wait for: `llama server listening at http://127.0.0.1:8001`
Keep this terminal open the whole session.
### Step 2 -- Launch your tool (PowerShell)
```powershell
cd C:\Users\m_ren\Desktop\Qwen3.5-Scripts
# Pick a model, pick a tool:
.\Start-WslServer.ps1 -Model 9B-Q4   # fast (default)
.\Start-WslServer.ps1 -Model 9B-Q6   # better quality
.\Start-WslServer.ps1 -Model 35B     # best quality
# Then launch your coding agent:
.\Start-ClaudeCode.ps1 -Model 9B-Q4
.\Start-Codex.ps1      -Model 9B-Q4
# Or browser chat (start server in chat mode first):
.\Start-WslServer.ps1 -Mode chat
.\Start-ChatUI.ps1
```
The `-Model` flag must match between `Start-WslServer.ps1` and your coding tool.
---
## All Script Flags
### Start-WslServer.ps1
```powershell
.\Start-WslServer.ps1                        # 9B-Q4, coding mode
.\Start-WslServer.ps1 -Model 9B-Q6           # 9B-Q6, coding mode
.\Start-WslServer.ps1 -Model 35B             # 35B, coding mode
.\Start-WslServer.ps1 -Mode chat             # 9B-Q4, chat mode
.\Start-WslServer.ps1 -Model 35B -Mode chat  # 35B, chat mode
```
### Start-ClaudeCode.ps1 / Start-Codex.ps1
```powershell
.\Start-ClaudeCode.ps1                # 9B-Q4 local (default)
.\Start-ClaudeCode.ps1 -Model 9B-Q6  # 9B-Q6 local
.\Start-ClaudeCode.ps1 -Model 35B    # 35B local
.\Start-ClaudeCode.ps1 -Cloud        # Anthropic cloud (real Claude)
.\Start-Codex.ps1                    # 9B-Q4 local (default)
.\Start-Codex.ps1 -Model 9B-Q6      # 9B-Q6 local
.\Start-Codex.ps1 -Model 35B        # 35B local
.\Start-Codex.ps1 -Cloud            # OpenAI cloud (real GPT)
```
---
## Server Modes
| Mode | Settings | Best for |
|------|----------|----------|
| coding (default) | temp=0.6, presence_penalty=OFF | Claude Code, Codex |
| chat | temp=1.0, presence_penalty=1.5 | Open WebUI conversation |
**Why presence_penalty=OFF for coding?**
With it on, the model avoids repeating tokens it has used -- bad for code that
legitimately repeats keywords like `return`, `self`, `import`, variable names, etc.
---
## Thinking Mode
Toggle per-prompt without restarting the server:
- `/think` -- enables chain-of-thought reasoning (slower, better for hard problems)
- `/no_think` -- fast direct answer (good for simple questions, boilerplate)
Examples in Claude Code:
```
/no_think   write a function to reverse a string
/think      design a Redis caching layer for this API
```
---
## Switching to Cloud
```powershell
.\Start-ClaudeCode.ps1 -Cloud   # Anthropic Claude (prompts for API key first time)
.\Start-Codex.ps1 -Cloud        # OpenAI GPT      (prompts for API key first time)
```
API keys are saved permanently to your Windows user environment after first entry.
- Anthropic: https://console.anthropic.com/settings/keys
- OpenAI:    https://platform.openai.com/api-keys
---
## Server Endpoints (port 8001)
| Endpoint | URL | Used by |
|----------|-----|---------|
| Health check | http://localhost:8001/health | Scripts |
| Built-in chat UI | http://localhost:8001 | Browser |
| Anthropic API | http://localhost:8001/v1/messages | Claude Code |
| OpenAI API | http://localhost:8001/v1/chat/completions | Codex CLI |
---
## VRAM Usage
```
RTX 4070 SUPER (12GB VRAM):
  9B-Q4:  model=5.1GB  cache=0.1GB  compute=0.5GB  free=~5.5GB
  9B-Q6:  model=7.5GB  cache=0.1GB  compute=0.5GB  free=~3.5GB
  35B:    model=~12GB in VRAM + ~5GB spills to RAM (MoE = low penalty)
```
---
## Keeping Everything Updated
Run weekly in WSL:
```bash
# Full update (apt + pip + npm + llama.cpp if changed)
~/qwen3.5/update-all.sh
# Quick update -- skips llama.cpp rebuild
~/qwen3.5/update-all.sh --skip-llama
```
Then push any script changes to GitHub:
```bash
cd /mnt/c/Users/m_ren/repos/qwen35-local-setup
git add .
git commit -m "describe changes"
git push
```
GitHub repo: https://github.com/maxrenke/qwen35-local-setup
---
## WSL File Locations
```
~/qwen3.5/
|-- llama.cpp/
|   |-- llama-cli
|   |-- llama-server          # API server
|   +-- ...
|-- unsloth/
|   |-- Qwen3.5-9B-GGUF/
|   |   |-- Qwen3.5-9B-UD-Q4_K_XL.gguf   (~6.5GB)
|   |   +-- Qwen3.5-9B-UD-Q6_K_XL.gguf   (~9GB)
|   +-- Qwen3.5-35B-A3B-GGUF/
|       +-- Qwen3.5-35B-A3B-UD-Q3_K_XL.gguf  (~17GB)
|-- serve_qwen35_9b.sh
|-- update-all.sh
+-- setup_qwen35_9b.sh
```
---
## Setup History
### 1. Verified WSL2 GPU access
```bash
nvidia-smi        # RTX 4070 SUPER visible, CUDA 13.2
ls /dev/dxg       # WSL2 GPU passthrough confirmed
```
### 2. Installed CUDA Toolkit 12.8
```bash
wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb && sudo apt-get update
sudo apt-get install -y cuda-toolkit-12-8
echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
```
### 3. Fixed WSL memory limit
WSL2 defaults to 16GB (half of 32GB). The llama.cpp build OOM-killed the compiler.
Fixed via Fix-WslMemory.ps1 which creates ~/.wslconfig:
```
[wsl2]
memory=24GB
swap=8GB
processors=8
```
### 4. Built llama.cpp with CUDA
```bash
git clone https://github.com/ggml-org/llama.cpp
cmake llama.cpp -B llama.cpp/build -DBUILD_SHARED_LIBS=OFF -DGGML_CUDA=ON -DGGML_CCACHE=OFF
cmake --build llama.cpp/build --config Release -j 4 \
    --target llama-cli llama-server llama-gguf-split
cp llama.cpp/build/bin/llama-* llama.cpp/
```
Note: `-j 4` not `-j` -- unlimited parallelism OOM-kills the build.
### 5. Downloaded models
```bash
pip install huggingface_hub hf_transfer --break-system-packages
# 9B Q4 (fast, default)
HF_HUB_ENABLE_HF_TRANSFER=1 hf download unsloth/Qwen3.5-9B-GGUF \
    --local-dir unsloth/Qwen3.5-9B-GGUF --include "*UD-Q4_K_XL*"
# 9B Q6 (better quality, still fits in VRAM)
HF_HUB_ENABLE_HF_TRANSFER=1 hf download unsloth/Qwen3.5-9B-GGUF \
    --local-dir unsloth/Qwen3.5-9B-GGUF --include "*UD-Q6_K_XL*"
# 35B-A3B Q3 (best quality, MoE -- spills to RAM)
HF_HUB_ENABLE_HF_TRANSFER=1 hf download unsloth/Qwen3.5-35B-A3B-GGUF \
    --local-dir unsloth/Qwen3.5-35B-A3B-GGUF --include "*UD-Q3_K_XL*"
```
### 6. Installed Claude Code + Codex CLI
```powershell
.\Install-ClaudeCodex.ps1
```
Note: MS Store "OpenAI Codex" is a different GUI app -- we use the npm CLI version.
---
## Troubleshooting
### Model not found error
```bash
ls ~/qwen3.5/unsloth/
# Re-download the missing model using commands in step 5 above
```
### Build OOM-killed during llama.cpp compile
1. Run Fix-WslMemory.ps1 on Windows (gives WSL 24GB)
2. Use -j 4 not -j in cmake build
3. Clean first: rm -rf llama.cpp/build
### Claude Code / Codex can't connect
- Make sure Start-WslServer.ps1 is running and showing "server listening"
- Check the -Model flag matches between server and client scripts
- Verify: curl http://localhost:8001/health should return {"status":"ok"}
### Wrong model loaded
The -Model flag in Start-ClaudeCode.ps1 / Start-Codex.ps1 sets the ANTHROPIC_MODEL
env var which tells Claude Code which model alias to request. It must match the
--alias set when the server was started. If mismatched, restart the server with
the correct -Model flag.
### git push asks for password in WSL
```bash
/mnt/c/Program\ Files/GitHub\ CLI/gh.exe auth setup-git
git push
```
### nvcc not found
```bash
source ~/.bashrc   # or open a fresh WSL terminal
```
---
## Model Selection Guide
```
Need speed?          --> 9B-Q4  (63 tok/s, good quality)
Need quality?        --> 9B-Q6  (50 tok/s, near full precision)
Need best results?   --> 35B    (25-40 tok/s, significantly stronger)
Need cloud quality?  --> -Cloud flag (uses real Claude / GPT)
```
---
*Setup completed March 2026.*
*Models: Qwen3.5-9B (Q4+Q6) and Qwen3.5-35B-A3B (Q3)*
*llama.cpp built with CUDA 12.8 on RTX 4070 SUPER, WSL2 Ubuntu 24*
*GitHub: https://github.com/maxrenke/qwen35-local-setup*
