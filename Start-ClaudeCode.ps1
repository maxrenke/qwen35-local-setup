# ============================================================
# Start-ClaudeCode.ps1
# Launches Claude Code -> local Qwen3.5-9B (or Anthropic cloud)
#
# Usage:
#   .\Start-ClaudeCode.ps1           -> local Qwen3.5-9B
#   .\Start-ClaudeCode.ps1 -Cloud    -> Anthropic cloud
# ============================================================
param([switch]$Cloud)
$npm     = "C:\Program Files\nodejs\npm.cmd"
$npmRoot = & $npm root -g 2>$null
$claude  = Join-Path (Split-Path $npmRoot) "claude.cmd"
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
if (-not (Test-Path $claude)) {
    Write-Host "  Claude Code not found." -ForegroundColor Red
    Write-Host "  Run Install-ClaudeCodex.ps1 first!" -ForegroundColor Yellow
    Read-Host "  Press Enter to exit"; exit 1
}
if ($Cloud) {
    Write-Host "  Mode: Anthropic Cloud (real Claude)" -ForegroundColor Magenta
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    $existingKey = [System.Environment]::GetEnvironmentVariable("ANTHROPIC_API_KEY", "User")
    if (-not $existingKey) {
        Write-Host "  No ANTHROPIC_API_KEY found." -ForegroundColor Yellow
        Write-Host "  Get yours at: https://console.anthropic.com/settings/keys" -ForegroundColor Gray
        Write-Host ""
        $apiKey = Read-Host "  Paste your Anthropic API key (sk-ant-...)"
        if ($apiKey) {
            [System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $apiKey, "User")
            $env:ANTHROPIC_API_KEY = $apiKey
            Write-Host "  Key saved permanently!" -ForegroundColor Green
        } else {
            Write-Host "  No key entered. Exiting." -ForegroundColor Red; exit 1
        }
    } else {
        $env:ANTHROPIC_API_KEY = $existingKey
        Write-Host "  ANTHROPIC_API_KEY found." -ForegroundColor Green
    }
    $env:ANTHROPIC_BASE_URL = ""
    $env:ANTHROPIC_MODEL    = ""
    $env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = ""
    Write-Host ""
    Write-Host "  Launching Claude Code -> Anthropic Cloud..." -ForegroundColor Yellow
} else {
    Write-Host "  Mode: Local Qwen3.5-9B (coding-optimized)" -ForegroundColor Green
    Write-Host "  Model:    Qwen3.5-9B-UD-Q4_K_XL (~6.5GB, full VRAM)" -ForegroundColor Gray
    Write-Host "  Settings: temp=0.6, presence_penalty=OFF, thinking=ON" -ForegroundColor Gray
    Write-Host "  Tip: prefix prompt with /no_think for faster responses" -ForegroundColor DarkGray
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    try {
        Invoke-WebRequest -Uri "http://localhost:8001/health" -TimeoutSec 3 -ErrorAction Stop | Out-Null
        Write-Host "  llama-server: UP at http://localhost:8001" -ForegroundColor Green
    } catch {
        Write-Host "  WARNING: llama-server not responding!" -ForegroundColor Red
        Write-Host "  Run Start-WslServer.ps1 first." -ForegroundColor Yellow
        Write-Host ""
        $continue = Read-Host "  Try anyway? (y/n)"
        if ($continue -ne "y") { exit 1 }
    }
    $env:ANTHROPIC_BASE_URL = "http://localhost:8001"
    $env:ANTHROPIC_API_KEY  = "sk-local-qwen"
    $env:ANTHROPIC_MODEL    = "unsloth/Qwen3.5-9B"
    $env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
    Write-Host ""
    Write-Host "  ANTHROPIC_BASE_URL = http://localhost:8001" -ForegroundColor Gray
    Write-Host "  ANTHROPIC_MODEL    = unsloth/Qwen3.5-9B" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Launching Claude Code -> Local Qwen3.5-9B..." -ForegroundColor Yellow
}
Write-Host ""
& $claude
