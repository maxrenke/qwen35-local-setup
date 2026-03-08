# ============================================================
# Start-ClaudeCode.ps1
# Launches Claude Code -> local Qwen3.5 (or Anthropic cloud)
#
# Usage:
#   .\Start-ClaudeCode.ps1                -> 9B Q4 (default)
#   .\Start-ClaudeCode.ps1 -Model 9B-Q6   -> 9B Q6 (better quality)
#   .\Start-ClaudeCode.ps1 -Model 35B     -> 35B-A3B (best quality)
#   .\Start-ClaudeCode.ps1 -Cloud         -> Anthropic cloud
# ============================================================
param(
    [ValidateSet("9B-Q4", "9B-Q6", "35B")]
    [string]$Model = "9B-Q4",
    [switch]$Cloud
)
$npm     = "C:\Program Files\nodejs\npm.cmd"
$npmRoot = & $npm root -g 2>$null
$claude  = Join-Path (Split-Path $npmRoot) "claude.cmd"
# Model alias must match what the server was started with
$aliasMap = @{
    "9B-Q4" = "unsloth/Qwen3.5-9B-Q4"
    "9B-Q6" = "unsloth/Qwen3.5-9B-Q6"
    "35B"   = "unsloth/Qwen3.5-35B"
}
$modelAlias = $aliasMap[$Model]
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
    Write-Host "  Mode: Local $Model (coding-optimized)" -ForegroundColor Green
    Write-Host "  Model alias: $modelAlias" -ForegroundColor Gray
    Write-Host "  Settings: temp=0.6, presence_penalty=OFF, thinking=ON" -ForegroundColor Gray
    Write-Host "  Tip: start server with .\Start-WslServer.ps1 -Model $Model" -ForegroundColor DarkGray
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
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
    $env:ANTHROPIC_BASE_URL = "http://localhost:8001"
    $env:ANTHROPIC_API_KEY  = "sk-local-qwen"
    $env:ANTHROPIC_MODEL    = $modelAlias
    $env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
    Write-Host ""
    Write-Host "  ANTHROPIC_BASE_URL = http://localhost:8001" -ForegroundColor Gray
    Write-Host "  ANTHROPIC_MODEL    = $modelAlias" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Launching Claude Code -> Local $Model..." -ForegroundColor Yellow
}
Write-Host ""
& $claude
