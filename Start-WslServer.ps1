# ============================================================
# Start-WslServer.ps1
# Launches llama-server in WSL with selectable model
# ============================================================
param(
    [ValidateSet("9B-Q4", "9B-Q6", "35B")]
    [string]$Model = "9B-Q4",
    [ValidateSet("coding", "chat")]
    [string]$Mode = "coding"
)
$wslExe  = "$env:SystemRoot\System32\wsl.exe"
$wslUser = "m_ren"
$wslHome = "/home/$wslUser"
switch ($Model) {
    "9B-Q4" {
        $modelFile = "unsloth/Qwen3.5-9B-GGUF/Qwen3.5-9B-UD-Q4_K_XL.gguf"
        $alias     = "unsloth/Qwen3.5-9B-Q4"
        $vramDesc  = "~6.5GB VRAM (fully in VRAM)"
        $speedDesc = "~63 tok/s"
        $qualDesc  = "Good -- fast everyday coding"
    }
    "9B-Q6" {
        $modelFile = "unsloth/Qwen3.5-9B-GGUF/Qwen3.5-9B-UD-Q6_K_XL.gguf"
        $alias     = "unsloth/Qwen3.5-9B-Q6"
        $vramDesc  = "~9GB VRAM (fully in VRAM)"
        $speedDesc = "~50 tok/s"
        $qualDesc  = "Better quality -- near full precision"
    }
    "35B" {
        $modelFile = "unsloth/Qwen3.5-35B-A3B-GGUF/Qwen3.5-35B-A3B-UD-Q3_K_XL.gguf"
        $alias     = "unsloth/Qwen3.5-35B"
        $vramDesc  = "~17GB (VRAM + RAM spillover, MoE = small penalty)"
        $speedDesc = "~25-40 tok/s"
        $qualDesc  = "Best quality -- significantly stronger reasoning"
    }
}
if ($Mode -eq "coding") {
    $temp            = "0.6"
    $presencePenalty = "0.0"
    $modeColor       = "Green"
    $modeDesc        = "temp=0.6, presence_penalty=OFF, thinking=ON"
} else {
    $temp            = "1.0"
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
# Kill any existing llama-server to free VRAM
Write-Host "  Killing any existing llama-server..." -ForegroundColor Yellow
Start-Process $wslExe -ArgumentList "-e", "bash", "-c", "pkill -f llama-server 2>/dev/null; sleep 1" -NoNewWindow -Wait
# Check model file via Windows UNC path to WSL filesystem
$winModelPath = "\\wsl$\Ubuntu$wslHome\qwen3.5\$modelFile"
if (-not (Test-Path $winModelPath)) {
    Write-Host ""
    Write-Host "  ERROR: Model file not found!" -ForegroundColor Red
    Write-Host "  Expected: $wslHome/qwen3.5/$modelFile" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Download it in WSL with:" -ForegroundColor Yellow
    switch ($Model) {
        "9B-Q4" { Write-Host "  cd ~/qwen3.5 && HF_HUB_ENABLE_HF_TRANSFER=1 hf download unsloth/Qwen3.5-9B-GGUF --local-dir unsloth/Qwen3.5-9B-GGUF --include '*UD-Q4_K_XL*'" -ForegroundColor Gray }
        "9B-Q6" { Write-Host "  cd ~/qwen3.5 && HF_HUB_ENABLE_HF_TRANSFER=1 hf download unsloth/Qwen3.5-9B-GGUF --local-dir unsloth/Qwen3.5-9B-GGUF --include '*UD-Q6_K_XL*'" -ForegroundColor Gray }
        "35B"   { Write-Host "  cd ~/qwen3.5 && HF_HUB_ENABLE_HF_TRANSFER=1 hf download unsloth/Qwen3.5-35B-A3B-GGUF --local-dir unsloth/Qwen3.5-35B-A3B-GGUF --include '*UD-Q3_K_XL*'" -ForegroundColor Gray }
    }
    Read-Host "  Press Enter to exit"; exit 1
}
Write-Host "  Model file found." -ForegroundColor Green
# Read template, substitute placeholders entirely in PowerShell (avoids all escaping issues),
# write result with no BOM and Unix line endings
$scriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$templatePath  = Join-Path $scriptDir "server_template.sh"
$scriptPath    = "$wslHome/qwen3.5/start_server_tmp.sh"
$winScriptPath = "\\wsl$\Ubuntu$scriptPath"
$utf8NoBom     = [System.Text.UTF8Encoding]::new($false)
$content = [System.IO.File]::ReadAllText($templatePath)
$content = $content.Replace("MODEL_FILE",     $modelFile)
$content = $content.Replace("MODEL_ALIAS",    $alias)
$content = $content.Replace("TEMP_VALUE",     $temp)
$content = $content.Replace("PRESENCE_VALUE", $presencePenalty)
[System.IO.File]::WriteAllText($winScriptPath, $content, $utf8NoBom)
# chmod using absolute path
Start-Process $wslExe -ArgumentList "-e", "chmod", "+x", $scriptPath -NoNewWindow -Wait
$lastLine = (Get-Content $winScriptPath | Select-Object -Last 1)
Write-Host "  Script ready. Last line: $lastLine" -ForegroundColor Gray
Write-Host ""
Write-Host "  Opening server in a new terminal window..." -ForegroundColor Yellow
Write-Host "  Keep that window open while using Claude Code or Codex." -ForegroundColor Yellow
Write-Host ""
$wtPath = (Get-Command wt -ErrorAction SilentlyContinue)?.Source
if ($wtPath) {
    Start-Process "wt.exe" -ArgumentList "-- wsl.exe bash $scriptPath"
} else {
    Start-Process "cmd.exe" -ArgumentList "/c wsl.exe bash $scriptPath"
}
$waitSecs = if ($Model -eq "35B") { 25 } elseif ($Model -eq "9B-Q6") { 15 } else { 10 }
Write-Host "  Waiting for model to load (~$waitSecs seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds $waitSecs
$serverUp = $false
for ($i = 1; $i -le 12; $i++) {
    try {
        Invoke-WebRequest -Uri "http://localhost:8001/health" -TimeoutSec 3 -ErrorAction Stop | Out-Null
        $serverUp = $true; break
    } catch {
        Write-Host "  Still loading... ($i/12)" -ForegroundColor Yellow
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
