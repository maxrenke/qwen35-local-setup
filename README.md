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
| `Start-OvernightAgent.ps1` | Runs Codex headlessly on a task (overnight builds) | Every overnight run |
| `Start-Tonight.ps1` | One-command bedtime launcher -- pick a project and go | Every overnight run |
| `Install-Superpowers.ps1` | Installs obra/superpowers skills for Codex + OpenCode | Done |
| `Update-Superpowers.ps1` | Pulls latest superpowers skills | Weekly |
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
---
## MCP Servers
Three MCP servers are configured to work with Claude Code and Opencode:
powershell, pob (Path of Building), and oculos (desktop UI automation).
### What is MCP?
MCP (Model Context Protocol) lets AI coding tools call external tools and
services. Each server exposes a set of tools the model can invoke during a
session -- for example, running PowerShell commands, reading PoB build files,
or clicking UI elements on your desktop.
### Configured MCP Servers
| Server | Repo | What it does |
|--------|------|-------------|
| `powershell` | `C:/Users/m_ren/repos/powershell-mcp` | Run PowerShell commands, manage files, check system info |
| `pob` | `C:/Users/m_ren/repos/pob-mcp` | Read and analyze Path of Building build files |
| `oculos` | `C:/Users/m_ren/repos/oculos-mcp-wrapper` | Automate Windows desktop UI (click, type, read elements) |
### Where MCP is Configured
| Tool | Config file | Status |
|------|-------------|--------|
| Claude Desktop | `%APPDATA%\Claude\claude_desktop_config.json` | powershell, pob, oculos |
| Claude Code | `~/.claude.json` (mcpServers key) | powershell, pob, oculos |
| Opencode | `~/.config/opencode/opencode.json` (mcp key) | powershell, pob, oculos |
| Codex desktop | N/A | MCP not supported |
### Using MCP Tools in Claude Code
MCP tools are available automatically once the server starts. You will be
prompted to allow each tool the first time it is used. To see available tools:
```
/mcp
```
### Using MCP Tools in Opencode
MCP servers start automatically when opencode launches. Tools appear in the
tool picker during a session.
### Thinking Mode with MCP
Use `/think` before complex multi-tool tasks for better results:
```
/think   use powershell to check disk space on all drives and summarize
/think   analyze my PoB build and suggest passive tree improvements
/no_think   what tools do you have available?
```
### Re-running MCP Setup
If you reinstall or move any MCP server repos, update the paths in:
- `%APPDATA%\Claude\claude_desktop_config.json` (Claude Desktop)
- `~/.claude.json` (Claude Code)
- `~/.config/opencode/opencode.json` (Opencode)
Then restart the respective tool.*Setup completed March 2026.*
*Models: Qwen3.5-9B (Q4+Q6) and Qwen3.5-35B-A3B (Q3)*
*llama.cpp built with CUDA 12.8 on RTX 4070 SUPER, WSL2 Ubuntu 24*
*GitHub: https://github.com/maxrenke/qwen35-local-setup*
---
## Overnight Agent (Headless Codex)
Run Codex fully autonomously on a task while you're away -- no interaction needed.
The agent starts the model server, runs `codex exec --full-auto`, streams all
output to a log file, and saves the final result when done.
Script: `Start-OvernightAgent.ps1`
---
### How to pass a prompt
Three options -- use whichever fits the situation:
**Option 1 -- prompt.txt next to the script (recommended for recurring tasks)**
Drop a `prompt.txt` in the same folder as `Start-OvernightAgent.ps1` and just run:
```powershell
.\Start-OvernightAgent.ps1
```
The script auto-detects it. No flags needed.
**Option 2 -- point at any prompt file anywhere**
```powershell
.\Start-OvernightAgent.ps1 -PromptFile "C:\Users\m_ren\repos\my-project\prompt.txt"
```
Good for keeping a prompt.txt inside each project repo.
**Option 3 -- inline string (quick one-offs)**
```powershell
.\Start-OvernightAgent.ps1 -Prompt "add docstrings to all functions in this repo"
```
Prompt resolution order: `-Prompt` > `-PromptFile` > `prompt.txt` next to script.
---
### All flags
```powershell
.\Start-OvernightAgent.ps1                                  # auto-detect prompt.txt, 9B-Q6, WorkDir = script folder
.\Start-OvernightAgent.ps1 -Model 9B-Q4                    # faster model
.\Start-OvernightAgent.ps1 -Model 35B                      # best quality model
.\Start-OvernightAgent.ps1 -WorkDir "C:\path\to\repo"      # point agent at a specific repo
.\Start-OvernightAgent.ps1 -SkipServerStart                 # skip WSL server launch (already running)
.\Start-OvernightAgent.ps1 -PromptFile ".\prompt.txt" -Model 9B-Q6 -WorkDir "C:\Users\m_ren\repos\my-project"
```
| Flag | Default | Description |
|------|---------|-------------|
| `-Prompt` | "" | Inline prompt string |
| `-PromptFile` | "" | Path to a .txt file containing the prompt |
| `-Model` | `9B-Q6` | Model to use: `9B-Q4`, `9B-Q6`, or `35B` |
| `-WorkDir` | script folder | Directory the agent will work in |
| `-SkipServerStart` | off | Skip WSL server launch if it's already running |
Note: overnight tasks default to `9B-Q6` (not `9B-Q4` like the interactive scripts)
for better output quality on long unattended runs.
---
### Logs
Every run creates a timestamped folder under `logs\` next to the script:
```
qwen35-local-setup\
+-- logs\
    +-- 2026-03-09_22-00-00\
        |-- agent.log          full stdout/stderr stream from codex
        |-- result.txt         final agent message only
        +-- prompt_used.txt    exact prompt that ran (for your records)
```
Useful for reviewing in the morning: `result.txt` has the summary, `agent.log`
has the full step-by-step of what the agent did.
---
### Recommended workflow
**Before you leave:**
1. Create or edit `prompt.txt` in your project folder describing the task
2. Run:
```powershell
cd C:\Users\m_ren\repos\qwen35-local-setup
.\Start-OvernightAgent.ps1 -WorkDir "C:\Users\m_ren\repos\my-project"
```
3. Watch the server come up and first few agent steps, then leave
**When you get back:**
```powershell
# Read the summary
Get-Content .\logs\<latest-timestamp>\result.txt
# Review the full run
Get-Content .\logs\<latest-timestamp>\agent.log | more
# See what files changed
cd C:\Users\m_ren\repos\my-project
git diff --stat
```
---
### Writing a good prompt.txt
The agent works best with clear structure. A solid prompt.txt includes:
- **Goal** -- one sentence on what you want built
- **Tech requirements** -- language, framework, any constraints
- **Deliverables** -- specific files it should create
- **Context** -- point it at relevant existing files or folders
Example structure:
```
Build a [thing] that does [X].
## Tech requirements
- Python 3.12, FastAPI
- No external cloud dependencies
- Save to: C:\Users\m_ren\repos\my-project\
## What to build
- server.py   -- the main app
- README.md   -- setup and usage instructions
- requirements.txt
## Context
Read the existing code in C:\Users\m_ren\repos\my-project\src\ before starting.
```
The more specific you are, the less time the agent wastes on decisions.
---
### Model choice for overnight runs
| Task | Recommended model | Why |
|------|------------------|-----|
| Straightforward build (CRUD, scripts, tools) | `9B-Q6` | Fast enough, good quality |
| Complex architecture, debugging, refactoring | `35B` | Much stronger reasoning |
| Quick test / smoke test of a prompt | `9B-Q4` | Fastest iteration |
---
### Example: monitoring dashboard (included prompt.txt)
A ready-to-use `prompt.txt` is included next to this script. It instructs the
agent to build a local GPU + system monitoring dashboard you can view on your
phone over Tailscale. To run it:
```powershell
.\Start-OvernightAgent.ps1
# or explicitly:
.\Start-OvernightAgent.ps1 -PromptFile ".\prompt.txt" -WorkDir "C:\Users\m_ren\repos\monitor-dashboard"
```
The agent will build:
- `monitor.py` -- Flask backend serving live GPU/CPU/RAM/disk stats
- An auto-refreshing HTML dashboard served on port 5000
- `requirements.txt` + `README.md`
View it on your phone at `http://<tailscale-ip>:5000` while on the same network.
---
## Superpowers (obra/superpowers)
Superpowers is a skills framework that changes how your coding agent behaves.
Instead of jumping straight into code, it makes the agent:
1. **Brainstorm** -- ask clarifying questions, explore alternatives, write a design doc
2. **Plan** -- break work into bite-sized tasks (2-5 min each) with exact file paths and verification steps
3. **TDD** -- enforce RED-GREEN-REFACTOR: write failing test, watch it fail, write minimal code, watch it pass
4. **Review** -- check each task against the plan before moving on
Skills trigger automatically. You don't invoke them manually -- the agent detects
what it's doing and loads the right skill. A 40k-star project with ~100 experiments/day
in autonomous runs reported; real-world results vary by model quality.
Repo: https://github.com/obra/superpowers
---
### Installation
Run once:
```powershell
.\Install-Superpowers.ps1
```
This clones superpowers into both WSL locations, wires the OpenCode plugin symlink,
and patches `~/.codex/AGENTS.md` to inject the bootstrap instruction.
Keep it updated:
```powershell
.\Update-Superpowers.ps1
```
---
### Scripts added
| Script | Purpose |
|--------|---------|
| `Install-Superpowers.ps1` | One-time install for Codex + OpenCode |
| `Update-Superpowers.ps1`  | `git pull` both installs |
---
### How superpowers loads (per tool)
**Codex** -- automatic via `~/.codex/AGENTS.md`. Every Codex session reads this
file on startup. The injected line tells Codex to run the bootstrap script, which
loads all skills into context before the agent does anything.
**OpenCode** -- via a plugin symlink at `~/.config/opencode/plugin/superpowers.js`.
OpenCode loads plugins on startup and injects superpowers context automatically via
the `chat.message` hook. Restart OpenCode after installing.
Verify it worked in OpenCode:
```
do you have superpowers?
```
---
### Using superpowers with the overnight agent
Add `-Superpowers` to any overnight run:
```powershell
# With auto-detected prompt.txt
.\Start-OvernightAgent.ps1 -Superpowers
# With a specific prompt file and model
.\Start-OvernightAgent.ps1 -PromptFile ".\prompt.txt" -Model 35B -Superpowers
# Inline prompt
.\Start-OvernightAgent.ps1 -Prompt "build a ROM metadata scraper" -Superpowers
```
When `-Superpowers` is set the script prepends the bootstrap instruction to your
prompt so the agent loads all skills before touching any code.
**When to use `-Superpowers`:**
| Task | Use superpowers? |
|------|-----------------|
| Complex new feature, unclear scope | Yes -- brainstorm + plan saves wasted work |
| Simple well-defined build (CRUD app, script) | Optional -- adds overhead but improves quality |
| Quick test of a prompt | No -- too much overhead for fast iteration |
| Debugging / fixing a specific bug | No -- systematic-debugging skill helps but brainstorm isn't needed |
---
### Personal skills (your own skills)
You can add your own skills that override the superpowers defaults.
**For Codex** -- create `~/.codex/skills/<skill-name>/SKILL.md`
**For OpenCode** -- create `~/.config/opencode/skills/<skill-name>/SKILL.md`
Skill priority: project skills > personal skills > superpowers skills.
Example -- a personal skill for your coding style:
```
~/.codex/skills/my-style/SKILL.md
```
```markdown
---
name: my-style
description: Use when writing any new code - applies personal style preferences
---
# My Coding Style
- Always use type hints in Python
- Prefer dataclasses over dicts for structured data
- Write docstrings for all public functions
- Keep functions under 30 lines
```
**Project-level skills** (per-repo) go in `.codex/skills/<name>/SKILL.md` inside
the repo itself. These take highest priority and are great for project-specific
context (architecture decisions, naming conventions, existing patterns).
---
### Skill reference (skills available out of the box)
| Skill | Triggers when... |
|-------|-----------------|
| `brainstorming` | You start describing something to build |
| `writing-plans` | Design is approved and implementation begins |
| `executing-plans` | A plan exists and work starts |
| `subagent-driven-development` | Parallel subagents are dispatched per task |
| `test-driven-development` | Any code is being written |
| `systematic-debugging` | A bug or failure is being investigated |
| `requesting-code-review` | A task or batch completes |
| `using-git-worktrees` | A new feature branch is created |
| `finishing-a-development-branch` | All tasks in a plan are done |
| `writing-skills` | You want to create a new skill |
---
## Start-Tonight.ps1 GÇö Bedtime Launcher
One script, one terminal, pick a project and go to sleep.
```powershell
cd C:\Users\m_ren\repos\qwen35-local-setup
.\Start-Tonight.ps1 -Project pob          # pob-mcp test coverage (branch: agent/test-coverage-phase1)
.\Start-Tonight.ps1 -Project psscripts    # powershell-scripts improvements (commits to main)
.\Start-Tonight.ps1 -Project pob -Model 35B           # use the big model
.\Start-Tonight.ps1 -Project psscripts -Superpowers   # with superpowers workflow
```
### Do I need two terminal windows?
No. The server starts in a background window automatically (you'll see it open
briefly), then the agent runs in the same terminal you launched from. You can
minimize everything and go to bed. One terminal is all you need.
The separate server window is just the WSL llama-server output -- it needs to
stay open in the background, but you don't need to interact with it.
### Projects registered
| -Project | Repo | Branch | What it does |
|----------|------|--------|-------------|
| `pob` | pob-mcp | agent/test-coverage-phase1 | Adds unit tests for bossReadiness, leveling, skillGem handlers |
| `psscripts` | powershell-scripts | main | Consolidates duplicates, adds -WhatIf, improves ROM/updater scripts |
### In the morning
```powershell
# pob-mcp results
Get-Content C:\Users\m_ren\repos\pob-mcp\AGENT_RUN_NOTES.md
& "C:\Program Files\Git\cmd\git.exe" -C C:\Users\m_ren\repos\pob-mcp log --oneline agent/test-coverage-phase1
# powershell-scripts results
Get-Content C:\Users\m_ren\repos\powershell-scripts\AGENT_RUN_NOTES.md
& "C:\Program Files\Git\cmd\git.exe" -C C:\Users\m_ren\repos\powershell-scripts log --oneline -10
```
### Adding a new project
To register a new project, open Start-Tonight.ps1 and add an entry to the
$projects hashtable:
```powershell
"myproject" = @{
    Label      = "my-repo (what it does)"
    PromptFile = "C:\Users\m_ren\repos\my-repo\prompt.txt"
    WorkDir    = "C:\Users\m_ren\repos\my-repo"
    Branch     = "agent/feature-branch"
    Notes      = "Check AGENT_RUN_NOTES.md"
}
```
Then just drop a `prompt.txt` and `TODO.md` in the repo and run:
```powershell
.\Start-Tonight.ps1 -Project myproject
```
