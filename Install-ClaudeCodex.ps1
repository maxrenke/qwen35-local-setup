# ============================================================
# Install-ClaudeCodex.ps1
# Installs Claude Code and OpenAI Codex CLI on Windows
# Run this ONCE before using the other scripts
# ============================================================
# Usage:
#   Right-click -> "Run with PowerShell" (as Admin)
#   or: powershell -ExecutionPolicy Bypass -File Install-ClaudeCodex.ps1
# ============================================================
$npm = "C:\Program Files\nodejs\npm.cmd"
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Installing Claude Code + Codex CLI" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
# --- Check npm ---
if (-not (Test-Path $npm)) {
    Write-Host ""
    Write-Host "  ERROR: npm not found at expected path." -ForegroundColor Red
    Write-Host "  Please install Node.js from https://nodejs.org first." -ForegroundColor Yellow
    Write-Host "  Then re-run this script." -ForegroundColor Yellow
    Read-Host "  Press Enter to exit"
    exit 1
}
$npmVersion = & $npm --version 2>&1
Write-Host ""
Write-Host "  npm found: v$npmVersion" -ForegroundColor Green
# --- Install Claude Code ---
Write-Host ""
Write-Host "  [1/2] Installing @anthropic-ai/claude-code..." -ForegroundColor Yellow
& $npm install -g @anthropic-ai/claude-code
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Claude Code install failed. Try running as Administrator." -ForegroundColor Red
    Read-Host "  Press Enter to exit"
    exit 1
}
Write-Host "  Claude Code installed!" -ForegroundColor Green
# --- Install Codex CLI ---
Write-Host ""
Write-Host "  [2/2] Installing @openai/codex..." -ForegroundColor Yellow
& $npm install -g @openai/codex
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Codex install failed. Try running as Administrator." -ForegroundColor Red
    Read-Host "  Press Enter to exit"
    exit 1
}
Write-Host "  Codex CLI installed!" -ForegroundColor Green
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  All done! Next steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. In WSL, start llama-server:" -ForegroundColor White
Write-Host "       ./serve_qwen35_9b.sh" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Then use one of these scripts:" -ForegroundColor White
Write-Host "       Start-ClaudeCode.ps1    -> Claude Code (local Qwen)" -ForegroundColor Gray
Write-Host "       Start-Codex.ps1         -> Codex CLI   (local Qwen)" -ForegroundColor Gray
Write-Host "       Start-ClaudeCode.ps1 -Cloud  -> Claude Code (Anthropic cloud)" -ForegroundColor Gray
Write-Host "       Start-Codex.ps1 -Cloud        -> Codex CLI   (OpenAI cloud)" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"
