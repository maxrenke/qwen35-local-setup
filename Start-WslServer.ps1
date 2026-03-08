# ============================================================
# Start-WslServer.ps1
# Launches Qwen3.5-9B llama-server in WSL
#
# Usage:
#   .\Start-WslServer.ps1              -> coding mode (default)
#   .\Start-WslServer.ps1 -Mode chat   -> general chat mode
# ============================================================
param(
    [ValidateSet("coding", "chat")]
    [string]$Mode = "coding",
    [string]$WslPath = "~/qwen3.5"
)
$wslExe = "$env:SystemRoot\System32\wsl.exe"
$model  = "unsloth/Qwen3.5-9B-GGUF/Qwen3.5-9B-UD-Q4_K_XL.gguf"
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Qwen3.5-9B llama-server  |  Mode: $Mode" -ForegroundColor Cyan
Write-Host "  Model: $model" -ForegroundColor DarkGray
Write-Host "============================================================" -ForegroundColor Cyan
if (-not (Test-Path $wslExe)) {
    Write-Host "  ERROR: WSL not found." -ForegroundColor Red
    Read-Host "  Press Enter to exit"; exit 1
}
if ($Mode -eq "coding") {
    $temp            = "0.6"
    $topP            = "0.95"
    $presencePenalty = "0.0"
    $modeColor       = "Green"
    $modeDesc        = "temp=0.6, presence_penalty=OFF, thinking=ON"
} else {
    $temp            = "1.0"
    $topP            = "0.95"
    $presencePenalty = "1.5"
    $modeColor       = "Magenta"
    $modeDesc        = "temp=1.0, presence_penalty=1.5, thinking=ON"
}
Write-Host "  Settings: $modeDesc" -ForegroundColor $modeColor
Write-Host "  VRAM:     ~6.5GB of 12GB (fully in VRAM, ~5.5GB free)" -ForegroundColor Gray
Write-Host "  Speed:    ~60-100 tok/s expected" -ForegroundColor Gray
Write-Host ""
$serverCmd = @"
cd $WslPath && ./llama.cpp/llama-server \
    --model $model \
    --alias "unsloth/Qwen3.5-9B" \
    --port 8001 \
    --ctx-size 32768 \
    --n-gpu-layers 999 \
    --temp $temp \
    --top-p $topP \
    --top-k 20 \
    --min-p 0.00 \
    --repeat-penalty 1.0 \
    --presence-penalty $presencePenalty \
    --cache-type-k q8_0 \
    --cache-type-v q8_0 \
    --flash-attn on \
    --batch-size 2048 \
    --ubatch-size 512 \
    --parallel 2 \
    --cont-batching \
    --jinja \
    --chat-template-kwargs '{\"enable_thinking\":true}'; exec bash
"@
Write-Host "  Opening server in a new terminal window..." -ForegroundColor Yellow
Write-Host "  Keep that window open while using Claude Code or Codex." -ForegroundColor Yellow
Write-Host ""
$wtPath = (Get-Command wt -ErrorAction SilentlyContinue)?.Source
if ($wtPath) {
    Start-Process "wt.exe" -ArgumentList "wsl.exe -e bash -c `"$serverCmd`""
} else {
    Start-Process "cmd.exe" -ArgumentList "/c wsl.exe -e bash -c `"$serverCmd`""
}
Write-Host "  Waiting for model to load (~8 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 8
$serverUp = $false
for ($i = 1; $i -le 8; $i++) {
    try {
        Invoke-WebRequest -Uri "http://localhost:8001/health" -TimeoutSec 3 -ErrorAction Stop | Out-Null
        $serverUp = $true; break
    } catch {
        Write-Host "  Still loading... ($i/8)" -ForegroundColor Yellow
        Start-Sleep -Seconds 4
    }
}
if ($serverUp) {
    Write-Host ""
    Write-Host "  Server is UP at http://localhost:8001" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Now run:" -ForegroundColor Cyan
    Write-Host "    .\Start-ClaudeCode.ps1   Claude Code -> Qwen3.5-9B" -ForegroundColor White
    Write-Host "    .\Start-Codex.ps1        Codex CLI   -> Qwen3.5-9B" -ForegroundColor White
    if ($Mode -eq "chat") {
        Write-Host "    .\Start-ChatUI.ps1       Browser chat UI" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "  Tip: Use /think or /no_think per-prompt to toggle" -ForegroundColor DarkGray
    Write-Host "  thinking mode without restarting the server." -ForegroundColor DarkGray
} else {
    Write-Host ""
    Write-Host "  Not responding yet ΓÇö model may still be loading." -ForegroundColor Yellow
    Write-Host "  Watch the server window for 'server listening'." -ForegroundColor Yellow
}
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"
