# ============================================================
# Start-WslServer.ps1
# Launches llama-server in WSL with selectable model
#
# Usage:
#   .\Start-WslServer.ps1                        -> 9B Q4 + coding mode (default)
#   .\Start-WslServer.ps1 -Model 9B-Q6           -> 9B Q6 (better quality)
#   .\Start-WslServer.ps1 -Model 35B             -> 35B-A3B Q3 (best quality)
#   .\Start-WslServer.ps1 -Mode chat             -> chat mode
#   .\Start-WslServer.ps1 -Model 35B -Mode chat  -> 35B in chat mode
# ============================================================
param(
    [ValidateSet("9B-Q4", "9B-Q6", "35B")]
    [string]$Model = "9B-Q4",
    [ValidateSet("coding", "chat")]
    [string]$Mode = "coding",
    [string]$WslPath = "~/qwen3.5"
)
$wslExe = "$env:SystemRoot\System32\wsl.exe"
# --------------------------------------------------------
# Model definitions
# --------------------------------------------------------
switch ($Model) {
    "9B-Q4" {
        $modelFile  = "unsloth/Qwen3.5-9B-GGUF/Qwen3.5-9B-UD-Q4_K_XL.gguf"
        $alias      = "unsloth/Qwen3.5-9B-Q4"
        $gpuLayers  = "999"           # fully in VRAM (~6.5GB of 12GB)
        $vramDesc   = "~6.5GB VRAM (fully in VRAM)"
        $speedDesc  = "~63 tok/s"
        $qualDesc   = "Good ΓÇö fast everyday coding"
    }
    "9B-Q6" {
        $modelFile  = "unsloth/Qwen3.5-9B-GGUF/Qwen3.5-9B-UD-Q6_K_XL.gguf"
        $alias      = "unsloth/Qwen3.5-9B-Q6"
        $gpuLayers  = "999"           # fully in VRAM (~9GB of 12GB)
        $vramDesc   = "~9GB VRAM (fully in VRAM)"
        $speedDesc  = "~50 tok/s"
        $qualDesc   = "Better quality ΓÇö near full precision"
    }
    "35B" {
        $modelFile  = "unsloth/Qwen3.5-35B-A3B-GGUF/Qwen3.5-35B-A3B-UD-Q3_K_XL.gguf"
        $alias      = "unsloth/Qwen3.5-35B"
        $gpuLayers  = "999"           # MoE: active layers in VRAM, idle experts spill to RAM
        $vramDesc   = "~17GB (VRAM + RAM spillover, MoE = small penalty)"
        $speedDesc  = "~25-40 tok/s"
        $qualDesc   = "Best quality ΓÇö significantly stronger reasoning"
    }
}
# --------------------------------------------------------
# Mode settings
# --------------------------------------------------------
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
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Qwen3.5 llama-server" -ForegroundColor Cyan
Write-Host "  Model:    $Model  --  $qualDesc" -ForegroundColor White
Write-Host "  Mode:     $Mode  --  $modeDesc" -ForegroundColor $modeColor
Write-Host "  VRAM:     $vramDesc" -ForegroundColor Gray
Write-Host "  Speed:    $speedDesc" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
if (-not (Test-Path $wslExe)) {
    Write-Host "  ERROR: WSL not found." -ForegroundColor Red
    Read-Host "  Press Enter to exit"; exit 1
}
# Check model file exists in WSL
$wslModelPath = "/mnt/c/Users/m_ren/qwen3.5/$modelFile" -replace "~", "/mnt/c/Users/m_ren"
$checkCmd = "test -f '$WslPath/$modelFile' && echo found || echo missing"
$tmpCheck = "$env:TEMP\model_check.txt"
Start-Process -FilePath $wslExe -ArgumentList "-e", "bash", "-c", $checkCmd `
    -NoNewWindow -Wait -RedirectStandardOutput $tmpCheck
$checkResult = Get-Content $tmpCheck -ErrorAction SilentlyContinue
if ($checkResult -ne "found") {
    Write-Host ""
    Write-Host "  ERROR: Model file not found!" -ForegroundColor Red
    Write-Host "  Expected: $WslPath/$modelFile" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Download it in WSL with:" -ForegroundColor Yellow
    switch ($Model) {
        "9B-Q6" {
            Write-Host "  hf download unsloth/Qwen3.5-9B-GGUF --local-dir unsloth/Qwen3.5-9B-GGUF --include '*UD-Q6_K_XL*'" -ForegroundColor Gray
        }
        "35B" {
            Write-Host "  hf download unsloth/Qwen3.5-35B-A3B-GGUF --local-dir unsloth/Qwen3.5-35B-A3B-GGUF --include '*UD-Q3_K_XL*'" -ForegroundColor Gray
        }
    }
    Read-Host "  Press Enter to exit"; exit 1
}
$serverCmd = @"
cd $WslPath && ./llama.cpp/llama-server \
    --model $modelFile \
    --alias "$alias" \
    --port 8001 \
    --ctx-size 32768 \
    --n-gpu-layers $gpuLayers \
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
Write-Host ""
Write-Host "  Opening server in a new terminal window..." -ForegroundColor Yellow
Write-Host "  Keep that window open while using Claude Code or Codex." -ForegroundColor Yellow
Write-Host ""
$wtPath = (Get-Command wt -ErrorAction SilentlyContinue)?.Source
if ($wtPath) {
    Start-Process "wt.exe" -ArgumentList "wsl.exe -e bash -c `"$serverCmd`""
} else {
    Start-Process "cmd.exe" -ArgumentList "/c wsl.exe -e bash -c `"$serverCmd`""
}
# Wait longer for 35B since it's bigger to load
$waitSecs = if ($Model -eq "35B") { 20 } elseif ($Model -eq "9B-Q6") { 12 } else { 8 }
Write-Host "  Waiting for model to load (~$waitSecs seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds $waitSecs
$serverUp = $false
for ($i = 1; $i -le 10; $i++) {
    try {
        Invoke-WebRequest -Uri "http://localhost:8001/health" -TimeoutSec 3 -ErrorAction Stop | Out-Null
        $serverUp = $true; break
    } catch {
        Write-Host "  Still loading... ($i/10)" -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    }
}
if ($serverUp) {
    Write-Host ""
    Write-Host "  Server is UP at http://localhost:8001" -ForegroundColor Green
    Write-Host "  Model alias: $alias" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Now run:" -ForegroundColor Cyan
    Write-Host "    .\Start-ClaudeCode.ps1 -Model $Model" -ForegroundColor White
    Write-Host "    .\Start-Codex.ps1      -Model $Model" -ForegroundColor White
    Write-Host ""
    Write-Host "  Tip: Use /think or /no_think per-prompt to toggle thinking." -ForegroundColor DarkGray
} else {
    Write-Host ""
    Write-Host "  Not responding yet -- model may still be loading." -ForegroundColor Yellow
    Write-Host "  Watch the server window for 'server listening'." -ForegroundColor Yellow
}
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"
