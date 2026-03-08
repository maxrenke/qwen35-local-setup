#!/bin/bash
# ============================================================
# update-all.sh
# Updates everything in WSL:
#   - apt packages (system + CUDA toolkit)
#   - pip tools (huggingface_hub, hf_transfer)
#   - npm global packages (claude code, codex)
#   - llama.cpp (rebuild from latest source)
# ============================================================
# Usage:
#   chmod +x update-all.sh
#   ./update-all.sh              # everything
#   ./update-all.sh --skip-llama # skip llama.cpp rebuild (faster)
# ============================================================
set -e
SKIP_LLAMA=false
for arg in "$@"; do
    [[ "$arg" == "--skip-llama" ]] && SKIP_LLAMA=true
done
QWEN_DIR="$HOME/qwen3.5"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'
ok()   { echo -e "${GREEN}  Γ£à $1${NC}"; }
info() { echo -e "${CYAN}  Γ₧£  $1${NC}"; }
warn() { echo -e "${YELLOW}  ΓÜá  $1${NC}"; }
section() { echo -e "\n${CYAN}============================================================${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${CYAN}============================================================${NC}"; }
section "WSL Full Update"
echo "  $(date)"
echo "  Skip llama.cpp rebuild: $SKIP_LLAMA"
# ------------------------------------------------------------
# 1. APT ΓÇö system packages + CUDA
# ------------------------------------------------------------
section "1/4  APT system packages"
info "Running apt update..."
sudo apt update -qq
info "Running apt upgrade..."
sudo apt upgrade -y
info "Removing orphaned packages..."
sudo apt autoremove -y
sudo apt autoclean -y
ok "APT done"
# ------------------------------------------------------------
# 2. PIP ΓÇö Python tools
# ------------------------------------------------------------
section "2/4  Python tools (pip)"
TOOLS=(
    "huggingface_hub"   # model downloads
    "hf_transfer"       # fast HF downloads
    "open-webui"        # chat UI (if installed)
)
for tool in "${TOOLS[@]}"; do
    if pip show "$tool" &>/dev/null; then
        info "Upgrading $tool..."
        pip install --upgrade "$tool" --break-system-packages --quiet
        ok "$tool upgraded"
    else
        warn "$tool not installed ΓÇö skipping"
    fi
done
ok "Pip done"
# ------------------------------------------------------------
# 3. NPM global packages (via Windows npm if available)
# ------------------------------------------------------------
section "3/4  npm global packages"
NPM_WIN="/mnt/c/Program Files/nodejs/npm.cmd"
if [ -f "$NPM_WIN" ]; then
    info "Updating @anthropic-ai/claude-code..."
    "$NPM_WIN" update -g @anthropic-ai/claude-code 2>/dev/null && ok "claude-code updated" || warn "claude-code update failed"
    info "Updating @openai/codex..."
    "$NPM_WIN" update -g @openai/codex 2>/dev/null && ok "codex updated" || warn "codex update failed"
else
    warn "Windows npm not found at expected path ΓÇö skipping npm updates"
    warn "Run Install-ClaudeCodex.ps1 on Windows to update manually"
fi
ok "npm done"
# ------------------------------------------------------------
# 4. llama.cpp ΓÇö pull latest and rebuild
# ------------------------------------------------------------
section "4/4  llama.cpp rebuild"
if [ "$SKIP_LLAMA" = true ]; then
    warn "Skipping llama.cpp rebuild (--skip-llama passed)"
    warn "Run without --skip-llama to rebuild with latest fixes"
else
    if [ ! -d "$QWEN_DIR/llama.cpp" ]; then
        warn "llama.cpp not found at $QWEN_DIR/llama.cpp ΓÇö skipping"
    else
        cd "$QWEN_DIR"
        info "Pulling latest llama.cpp..."
        git -C llama.cpp pull
        # Check if anything changed
        CHANGED=$(git -C llama.cpp diff HEAD@{1} HEAD --name-only 2>/dev/null | wc -l)
        if [ "$CHANGED" -eq 0 ]; then
            ok "llama.cpp already up to date ΓÇö skipping rebuild"
        else
            info "Changes detected ($CHANGED files) ΓÇö rebuilding with CUDA..."
            info "This takes ~15-25 minutes. Use --skip-llama to skip next time."
            echo ""
            # Clean old build
            rm -rf llama.cpp/build
            # Configure
            cmake llama.cpp -B llama.cpp/build \
                -DBUILD_SHARED_LIBS=OFF \
                -DGGML_CUDA=ON \
                -DGGML_CCACHE=OFF \
                --log-level=WARNING
            # Build with -j 4 to avoid OOM (learned the hard way!)
            cmake --build llama.cpp/build \
                --config Release -j 4 \
                --target llama-cli llama-server llama-gguf-split
            # Deploy binaries
            cp llama.cpp/build/bin/llama-* llama.cpp/
            ok "llama.cpp rebuilt successfully"
        fi
    fi
fi
# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------
section "Update Complete"
echo ""
echo "  Component         Status"
echo "  ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ     ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ"
echo "  APT packages    Γ£à updated"
echo "  pip tools       Γ£à updated"
echo "  npm (Windows)   Γ£à updated"
if [ "$SKIP_LLAMA" = true ]; then
echo "  llama.cpp       ΓÅ¡  skipped"
else
echo "  llama.cpp       Γ£à checked/rebuilt"
fi
echo ""
echo "  Run ./serve_qwen35_9b.sh to start the model server."
echo ""
