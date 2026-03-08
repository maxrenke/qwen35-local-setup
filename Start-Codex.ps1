# ============================================================
# Start-Codex.ps1
# Launches Codex CLI -> local Qwen3.5-9B (or OpenAI cloud)
#
# Usage:
#   .\Start-Codex.ps1           -> local Qwen3.5-9B
#   .\Start-Codex.ps1 -Cloud    -> OpenAI cloud
# ============================================================
param([switch]$Cloud)
$npm     = "C:\Program Files\nodejs\npm.cmd"
$npmRoot = & $npm root -g 2>$null
$codex   = Join-Path (Split-Path $npmRoot) "codex.cmd"
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
if (-not (Test-Path $codex)) {
    Write-Host "  Codex CLI not found." -ForegroundColor Red
    Write-Host "  Run Install-ClaudeCodex.ps1 first!" -ForegroundColor Yellow
    Read-Host "  Press Enter to exit"; exit 1
}
if ($Cloud) {
    Write-Host "  Mode: OpenAI Cloud (real GPT)" -ForegroundColor Magenta
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    $existingKey = [System.Environment]::GetEnvironmentVariable("OPENAI_API_KEY", "User")
    if (-not $existingKey) {
        Write-Host "  No OPENAI_API_KEY found." -ForegroundColor Yellow
        Write-Host "  Get yours at: https://platform.openai.com/api-keys" -ForegroundColor Gray
        Write-Host ""
        $apiKey = Read-Host "  Paste your OpenAI API key (sk-...)"
        if ($apiKey) {
            [System.Environment]::SetEnvironmentVariable("OPENAI_API_KEY", $apiKey, "User")
            $env:OPENAI_API_KEY = $apiKey
            Write-Host "  Key saved permanently!" -ForegroundColor Green
        } else {
            Write-Host "  No key entered. Exiting." -ForegroundColor Red; exit 1
        }
    } else {
        $env:OPENAI_API_KEY = $existingKey
        Write-Host "  OPENAI_API_KEY found." -ForegroundColor Green
    }
    $env:OPENAI_BASE_URL = ""
    $env:OPENAI_MODEL    = ""
    Write-Host ""
    Write-Host "  Launching Codex -> OpenAI Cloud..." -ForegroundColor Yellow
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
    $env:OPENAI_BASE_URL = "http://localhost:8001/v1"
    $env:OPENAI_API_KEY  = "sk-local-qwen"
    $env:OPENAI_MODEL    = "unsloth/Qwen3.5-9B"
    Write-Host ""
    Write-Host "  OPENAI_BASE_URL = http://localhost:8001/v1" -ForegroundColor Gray
    Write-Host "  OPENAI_MODEL    = unsloth/Qwen3.5-9B" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Launching Codex -> Local Qwen3.5-9B..." -ForegroundColor Yellow
}
Write-Host ""
& $codex
