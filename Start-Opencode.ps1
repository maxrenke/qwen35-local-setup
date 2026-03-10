# ============================================================
# Start-Opencode.ps1
# Launches opencode -> local Qwen3.5 (or cloud)
#
# Usage:
#   .\Start-Opencode.ps1                -> 9B-Q4 local (default)
#   .\Start-Opencode.ps1 -Model 9B-Q6  -> 9B-Q6 local
#   .\Start-Opencode.ps1 -Model 35B    -> 35B local
#   .\Start-Opencode.ps1 -Cloud        -> cloud providers (Google etc)
# ============================================================
param(
    [ValidateSet("9B-Q4", "9B-Q6", "35B")]
    [string]$Model = "9B-Q4",
    [switch]$Cloud
)
$opencode = "$env:APPDATA\npm\opencode.ps1"
$aliasMap = @{
    "9B-Q4" = "unsloth/Qwen3.5-9B-Q4"
    "9B-Q6" = "unsloth/Qwen3.5-9B-Q6"
    "35B"   = "unsloth/Qwen3.5-35B"
}
$modelAlias = $aliasMap[$Model]
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
if (-not (Test-Path $opencode)) {
    Write-Host "  opencode not found." -ForegroundColor Red
    Write-Host "  Install it with: npm install -g opencode-ai" -ForegroundColor Yellow
    Read-Host "  Press Enter to exit"; exit 1
}
if ($Cloud) {
    Write-Host "  Mode: Cloud providers" -ForegroundColor Magenta
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Launching opencode (cloud mode)..." -ForegroundColor Yellow
    Write-Host ""
    & $opencode
} else {
    Write-Host "  Mode: Local $Model" -ForegroundColor Green
    Write-Host "  Model: $modelAlias" -ForegroundColor Gray
    Write-Host "  Tip: start server with .\Start-WslServer.ps1 -Model $Model" -ForegroundColor DarkGray
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    # Check server is up
    try {
        Invoke-WebRequest -Uri "http://localhost:8001/health" -TimeoutSec 3 -ErrorAction Stop | Out-Null
        Write-Host "  llama-server: UP at http://localhost:8001" -ForegroundColor Green
    } catch {
        Write-Host "  WARNING: llama-server not responding!" -ForegroundColor Red
        Write-Host "  Run: .\Start-WslServer.ps1 -Model $Model" -ForegroundColor Yellow
        Write-Host ""
        $continue = Read-Host "  Try anyway? (y/n)"
        if ($continue -ne "y") { exit 1 }
    }
    Write-Host ""
    Write-Host "  Launching opencode -> Local $Model..." -ForegroundColor Yellow
    Write-Host "  Select model: qwen / $modelAlias" -ForegroundColor DarkGray
    Write-Host ""
    # Launch opencode with the model pre-selected via env var
    $env:OPENAI_API_KEY = "local"
    & $opencode --model "qwen/$modelAlias"
}
