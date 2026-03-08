# Qwen3.5-9B Local AI ΓÇö Setup & Usage Guide
Run **Qwen3.5-9B** fully locally on your RTX 4070 SUPER via WSL2, and use it as
the backend for **Claude Code** and **OpenAI Codex CLI** ΓÇö free, private, no API costs.
---
## Your Hardware
| Component | Spec |
|-----------|------|
| CPU | AMD Ryzen 7 5800XT (8c / 16t) |
| RAM | 32GB DDR4 @ 3200MHz |
| GPU | NVIDIA RTX 4070 SUPER ΓÇö 12GB VRAM |
| OS | Windows 10 Pro + WSL2 (Ubuntu 24) |
## Why Qwen3.5-9B?
- Beats Qwen3-14B and even Qwen3-30B on most benchmarks despite being smaller
- Fits entirely in 12GB VRAM (~6.5GB used, ~5.5GB free) ΓåÆ 60ΓÇô100+ tok/s
- Hybrid reasoning: thinking mode ON for hard problems, OFF for speed
- 256K context window, strong at coding, tool calling, agentic tasks
- Completely free and private ΓÇö runs 100% on your machine
---
## Scripts in This Folder
| Script | Purpose | Run once? |
|--------|---------|-----------|
| `Fix-WslMemory.ps1` | Gives WSL 24GB RAM (required to compile llama.cpp) | Γ£à Done |
| `Install-ClaudeCodex.ps1` | Installs Claude Code + Codex CLI via npm | Γ£à Done |
| `Start-WslServer.ps1` | Starts Qwen3.5-9B llama-server in WSL | Every session |
| `Start-ClaudeCode.ps1` | Launches Claude Code ΓåÆ local Qwen (or cloud) | Every session |
| `Start-Codex.ps1` | Launches Codex CLI ΓåÆ local Qwen (or cloud) | Every session |
| `Start-ChatUI.ps1` | Launches Open WebUI browser chat interface | Every session |
---
## Daily Workflow
### Step 1 ΓÇö Start the model server (WSL)
Open a WSL terminal and run:
```bash
cd ~/qwen3.5
./serve_qwen35_9b.sh
```
Wait until you see:
```
llama server listening at http://127.0.0.1:8001
```
Keep this terminal open. The server runs until you close it or press Ctrl+C.
### Step 2 ΓÇö Launch your coding tool (PowerShell)
Open PowerShell and navigate to this folder:
```powershell
cd C:\Users\m_ren\Desktop\Qwen3.5-Scripts
```
Then pick your tool:
```powershell
.\Start-ClaudeCode.ps1    # Claude Code  ΓåÆ local Qwen3.5-9B
.\Start-Codex.ps1         # Codex CLI    ΓåÆ local Qwen3.5-9B
```
Or for browser chat (start server in chat mode first):
```powershell
.\Start-WslServer.ps1 -Mode chat
.\Start-ChatUI.ps1
# Browser opens automatically at http://localhost:8080
```
---
## Server Modes
The server has two modes ΓÇö switch by restarting with a different flag:
| Mode | Command | Settings | Best for |
|------|---------|----------|----------|
| Coding (default) | `.\Start-WslServer.ps1` | temp=0.6, presence_penalty=OFF | Claude Code, Codex |
| Chat | `.\Start-WslServer.ps1 -Mode chat` | temp=1.0, presence_penalty=1.5 | Open WebUI conversation |
**Why presence_penalty=OFF for coding?**
With it on, the model avoids repeating tokens it has already used ΓÇö good for prose,
bad for code where you need to repeat keywords like `return`, `self`, `import`,
variable names, etc.
---
## Thinking Mode
Qwen3.5 supports hybrid reasoning ΓÇö you can toggle thinking per-prompt without
restarting the server:
- `/think` at the start of a prompt ΓåÆ enables chain-of-thought reasoning
- `/no_think` at the start of a prompt ΓåÆ fast direct answer
**Thinking ON** (default): slower but better for complex problems, architecture
decisions, debugging tricky issues.
**Thinking OFF**: faster, good for simple questions, boilerplate, quick lookups.
Example in Claude Code:
```
/no_think write a function to reverse a string
/think    design a caching layer for this API with Redis
```
---
## Switching to Cloud
Any script accepts a `-Cloud` flag to point at the real cloud API instead.
It will prompt you for an API key on first use and save it permanently.
```powershell
.\Start-ClaudeCode.ps1 -Cloud   # ΓåÆ Anthropic Claude (needs ANTHROPIC_API_KEY)
.\Start-Codex.ps1 -Cloud        # ΓåÆ OpenAI GPT      (needs OPENAI_API_KEY)
```
Get API keys:
- Anthropic: https://console.anthropic.com/settings/keys
- OpenAI:    https://platform.openai.com/api-keys
To revert to local after using cloud, just run the script without `-Cloud`.
---
## Server Endpoints
Once `serve_qwen35_9b.sh` is running, these are all live on port 8001:
| Endpoint | URL | Used by |
|----------|-----|---------|
| Health check | http://localhost:8001/health | Scripts (auto-check) |
| Built-in chat UI | http://localhost:8001 | Browser (basic) |
| Anthropic API | http://localhost:8001/v1/messages | Claude Code |
| OpenAI API | http://localhost:8001/v1/chat/completions | Codex CLI |
The server speaks both Anthropic and OpenAI API formats simultaneously on the same port.
---
## VRAM & Performance
```
RTX 4070 SUPER (12GB VRAM) breakdown when running Qwen3.5-9B:
  Model:    ~5.1 GB
  KV cache: ~0.1 GB  (grows with context length)
  Compute:  ~0.5 GB
  Free:     ~5.5 GB  ΓåÉ plenty of headroom
```
Expected speeds:
- **Prompt processing**: ~100 tok/s
- **Generation**: ~63 tok/s
- **Context**: up to 32,768 tokens (set in serve script)
---
## WSL File Locations
```
~/qwen3.5/
Γö£ΓöÇΓöÇ llama.cpp/                        # Built inference engine
Γöé   Γö£ΓöÇΓöÇ llama-cli                     # Interactive CLI
Γöé   Γö£ΓöÇΓöÇ llama-server                  # API server (what we use)
Γöé   ΓööΓöÇΓöÇ ...
Γö£ΓöÇΓöÇ unsloth/
Γöé   ΓööΓöÇΓöÇ Qwen3.5-9B-GGUF/
Γöé       ΓööΓöÇΓöÇ Qwen3.5-9B-UD-Q4_K_XL.gguf   # The model (~6.5GB)
Γö£ΓöÇΓöÇ serve_qwen35_9b.sh                # Server launch script
Γö£ΓöÇΓöÇ setup_qwen35_9b.sh                # One-time setup script
Γö£ΓöÇΓöÇ claude_code_config.sh             # WSL env config (optional)
ΓööΓöÇΓöÇ codex_config.sh                   # WSL env config (optional)
```
---
## Setup History (What We Did)
Here's everything that was configured to get here, in order:
### 1. Verified WSL2 GPU access
```bash
nvidia-smi        # Γ£à RTX 4070 SUPER visible, CUDA 13.2
nvcc --version    # Γ¥î Not installed ΓÇö fixed next
ls /dev/dxg       # Γ£à WSL2 GPU passthrough working
```
### 2. Installed CUDA Toolkit 12.8 in WSL
```bash
wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get install -y cuda-toolkit-12-8
echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
```
### 3. Fixed WSL memory limit
WSL2 defaults to 16GB (half of your 32GB RAM). Building llama.cpp with full
parallelism OOM-killed the compiler. Fixed by creating `~/.wslconfig`:
```
[wsl2]
memory=24GB
swap=8GB
processors=8
```
Then ran `wsl --shutdown` to apply. Script: `Fix-WslMemory.ps1`
### 4. Built llama.cpp with CUDA
```bash
cd ~/qwen3.5
git clone https://github.com/ggml-org/llama.cpp
cmake llama.cpp -B llama.cpp/build \
    -DBUILD_SHARED_LIBS=OFF \
    -DGGML_CUDA=ON \
    -DGGML_CCACHE=OFF
cmake --build llama.cpp/build \
    --config Release -j 4 \        # -j 4 = limit parallel jobs to avoid OOM
    --target llama-cli llama-server llama-gguf-split
cp llama.cpp/build/bin/llama-* llama.cpp/
```
Note: `-j 4` (not `-j`) is critical ΓÇö unlimited parallelism OOM-kills the build.
`-DGGML_CCACHE=OFF` silences a harmless ccache warning.
### 5. Downloaded the model
```bash
pip install huggingface_hub hf_transfer --break-system-packages
HF_HUB_ENABLE_HF_TRANSFER=1 hf download unsloth/Qwen3.5-9B-GGUF \
    --local-dir unsloth/Qwen3.5-9B-GGUF \
    --include "*UD-Q4_K_XL*"
```
### 6. Tested the model
```bash
./llama.cpp/llama-cli \
    --model unsloth/Qwen3.5-9B-GGUF/Qwen3.5-9B-UD-Q4_K_XL.gguf \
    --n-gpu-layers 999 \
    --ctx-size 2048 \
    --temp 0.7 --top-p 0.8 --top-k 20 --presence-penalty 0.0 \
    -p "Write a Python function that returns the fibonacci sequence." \
    --no-display-prompt -n 200
# Result: Γ£à 103 tok/s prompt, 63 tok/s generation
```
### 7. Installed Claude Code + Codex CLI on Windows
```powershell
.\Install-ClaudeCodex.ps1
# Installs @anthropic-ai/claude-code and @openai/codex via npm
```
Note: The MS Store "OpenAI Codex" app is a different product ΓÇö a GUI desktop
app hardcoded to OpenAI's cloud. Our `Start-Codex.ps1` uses the npm CLI version
(`@openai/codex`) which supports custom endpoints via environment variables.
---
## Troubleshooting
### Server won't start / model not found
```bash
ls ~/qwen3.5/unsloth/Qwen3.5-9B-GGUF/
# Should show: Qwen3.5-9B-UD-Q4_K_XL.gguf
# If missing, re-run the download command in step 5 above
```
### Build gets OOM-killed (Killed / Terminated spam)
WSL ran out of memory during compilation. Two fixes:
1. Run `Fix-WslMemory.ps1` on Windows to give WSL 24GB
2. Use `-j 4` not `-j` in the cmake build command
3. Clean the failed build first: `rm -rf llama.cpp/build`
### Claude Code / Codex can't connect to server
The scripts check `http://localhost:8001/health` automatically. If it fails:
- Make sure `serve_qwen35_9b.sh` is running in WSL
- Wait for `server listening` to appear in the server window
- Check the server window for error messages
### Gibberish output from the model
- Context length may be set too low ΓÇö the serve script uses 32768 which should be fine
- Try adding `--cache-type-k bf16 --cache-type-v bf16` to the serve script
### nvcc not found after installing CUDA
```bash
source ~/.bashrc
# or open a fresh WSL terminal
nvcc --version   # should now show 12.8
```
### WSL using old memory limit after Fix-WslMemory.ps1
```powershell
wsl --shutdown   # on Windows PowerShell
# Then reopen WSL
```
---
## Model Quantization Reference
The model we use (`UD-Q4_K_XL`) is Unsloth's Dynamic 4-bit quantization ΓÇö important
layers are kept at 8-bit or 16-bit precision while less sensitive layers are
compressed to 4-bit. This gives near full-precision quality at ~40% of the size.
| Quant | Size | Quality | Notes |
|-------|------|---------|-------|
| UD-Q2_K_XL | ~3.5GB | Good | Minimum recommended |
| UD-Q4_K_XL | ~6.5GB | Great | **What we use ΓÇö best balance** |
| UD-Q6_K_XL | ~9GB | Excellent | Fits in 12GB VRAM |
| BF16 | ~19GB | Perfect | Too large for 12GB VRAM |
---
## Why Not a Bigger Model?
| Model | VRAM needed | Fits in 12GB? | Speed | vs 9B quality |
|-------|-------------|---------------|-------|---------------|
| Qwen3.5-9B Q4 | ~6.5GB | Γ£à fully | ~63 tok/s | baseline |
| Qwen3-14B Q4 | ~8.5GB | Γ£à fully | ~45 tok/s | Γ¥î worse (older arch) |
| Qwen3.5-27B Q4 | ~17GB | ΓÜá∩╕Å spills to RAM | ~20 tok/s | Γ£à better |
| Qwen3.5-35B-A3B Q4 | ~22GB | ΓÜá∩╕Å spills to RAM | ~15 tok/s | Γ£à much better |
Qwen3.5-9B beats Qwen3-14B because it's a newer architecture ΓÇö bigger parameter
count does not automatically win across generations. The 27B and 35B-A3B are
genuinely better but would require significant RAM spillover on your hardware,
dropping speed to ~15-20 tok/s which can make coding agents feel sluggish.
---
*Setup completed March 2026. Model: unsloth/Qwen3.5-9B-GGUF UD-Q4_K_XL*
*llama.cpp built with CUDA 12.8, RTX 4070 SUPER, WSL2 Ubuntu 24*
