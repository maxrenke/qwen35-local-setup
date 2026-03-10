# ============================================================
# Start-OvernightAgent.ps1
# Starts llama-server + runs codex headlessly on a task.
#
# Uses codex 0.112.x (Rust binary, stable on Windows).
# Do NOT upgrade codex past 0.112.x -- later versions switched to /v1/responses
# which llama-server does not support. opencode (Bun) segfaults on this machine.
#
# Usage:
#   .\Start-OvernightAgent.ps1 -Prompt "build me a thing"
#   .\Start-OvernightAgent.ps1 -PromptFile ".\prompt.txt"
#   .\Start-OvernightAgent.ps1 -PromptFile ".\prompt.txt" -Model 9B-Q6
#   .\Start-OvernightAgent.ps1 -PromptFile ".\prompt.txt" -WorkDir "C:\repos\project"
#   .\Start-OvernightAgent.ps1 -PromptFile ".\prompt.txt" -Superpowers
#
# Prompt resolution order:
#   1. -Prompt string  2. -PromptFile path  3. prompt.txt next to this script
#
# Output:
#   Logs written to .\logs\<timestamp>\
#   Final agent output in logs\<timestamp>\agent.log
#   Last agent message in logs\<timestamp>\result.txt
# ============================================================
param(
    [string]$Prompt      = "",
    [string]$PromptFile  = "",
    [string]$WorkDir     = "",
    [ValidateSet("9B-Q4", "9B-Q6", "35B")]
    [string]$Model = "9B-Q6",
    [switch]$SkipServerStart,
    [switch]$Superpowers
)
$scriptDir = Split-Path $MyInvocation.MyCommand.Path
# ── Paths ────────────────────────────────────────────────────
# codex 0.112.x Rust binary -- uses /v1/chat/completions, stable on Windows
$codex    = "$env:APPDATA\npm\node_modules\@openai\codex\node_modules\@openai\codex-win32-x64\vendor\x86_64-pc-windows-msvc\codex\codex.exe"
$wslExe   = "$env:SystemRoot\System32\wsl.exe"
$wslUser  = "m_ren"
$wslHome  = "/home/$wslUser"
$logsRoot = Join-Path $scriptDir "logs"
$runStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logDir   = Join-Path $logsRoot $runStamp
# codex model string must match the alias served by llama-server
$aliasMap = @{
    "9B-Q4" = "unsloth/Qwen3.5-9B-Q4"
    "9B-Q6" = "unsloth/Qwen3.5-9B-Q6"
    "35B"   = "unsloth/Qwen3.5-35B"
}
$modelAlias = $aliasMap[$Model]
# ── Resolve prompt ───────────────────────────────────────────
$resolvedPrompt = ""
$promptSource   = ""
if ($Prompt -ne "") {
    $resolvedPrompt = $Prompt
    $promptSource   = "inline -Prompt argument"
}
elseif ($PromptFile -ne "") {
    if (-not (Test-Path $PromptFile)) {
        Write-Host "  ERROR: PromptFile not found: $PromptFile" -ForegroundColor Red
        exit 1
    }
    $resolvedPrompt = Get-Content $PromptFile -Raw
    $promptSource   = "file: $PromptFile"
}
else {
    $autoPrompt = Join-Path $scriptDir "prompt.txt"
    if (Test-Path $autoPrompt) {
        $resolvedPrompt = Get-Content $autoPrompt -Raw
        $promptSource   = "auto-detected: $autoPrompt"
    }
    else {
        Write-Host ""
        Write-Host "  ERROR: No prompt provided." -ForegroundColor Red
        Write-Host "    1. Pass a prompt:  -Prompt 'do a thing'" -ForegroundColor Gray
        Write-Host "    2. Pass a file:    -PromptFile .\prompt.txt" -ForegroundColor Gray
        Write-Host "    3. Drop a file:    create prompt.txt next to this script" -ForegroundColor Gray
        Write-Host ""
        exit 1
    }
}
$resolvedPrompt = $resolvedPrompt.Trim()
# ── Optionally prepend superpowers bootstrap ─────────────────
if ($Superpowers) {
    $spInstalled = Test-Path "\\wsl$\Ubuntu\home\m_ren\.codex\superpowers\.git"
    if (-not $spInstalled) {
        Write-Host "  ERROR: -Superpowers set but superpowers not installed." -ForegroundColor Red
        Write-Host "  Run: .\Install-Superpowers.ps1 first." -ForegroundColor Yellow
        exit 1
    }
    $spPreamble = @"
Before doing ANYTHING else: run ``~/.codex/superpowers/.codex/superpowers-codex bootstrap`` and follow all the instructions it returns. Load and apply all relevant skills before proceeding with the task below.
---
"@
    $resolvedPrompt = $spPreamble + $resolvedPrompt
    $promptSource   = "$promptSource [+superpowers]"
}
# ── Resolve working directory ────────────────────────────────
if ($WorkDir -eq "") { $WorkDir = $scriptDir }
if (-not (Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir | Out-Null }
# ── Create log dir ───────────────────────────────────────────
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$logFile    = Join-Path $logDir "agent.log"
$resultFile = Join-Path $logDir "result.txt"
$promptLog  = Join-Path $logDir "prompt_used.txt"
$resolvedPrompt | Out-File -FilePath $promptLog -Encoding UTF8
# ── Header ───────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Overnight Agent (codex 0.112)" -ForegroundColor Cyan
Write-Host "  Model:       $Model  ($modelAlias)" -ForegroundColor White
Write-Host "  WorkDir:     $WorkDir" -ForegroundColor White
Write-Host "  Prompt:      $promptSource" -ForegroundColor White
Write-Host "  Superpowers: $(if ($Superpowers) { 'ON' } else { 'off' })" -ForegroundColor $(if ($Superpowers) { "Magenta" } else { "DarkGray" })
Write-Host "  Logs:        $logDir" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
$preview = if ($resolvedPrompt.Length -gt 300) { $resolvedPrompt.Substring(0,300) + "..." } else { $resolvedPrompt }
Write-Host "  Prompt preview:" -ForegroundColor DarkGray
Write-Host "  $($preview -replace "`n", "`n  ")" -ForegroundColor Gray
Write-Host ""
# ── Sanity checks ────────────────────────────────────────────
if (-not (Test-Path $codex)) {
    Write-Host "  ERROR: codex not found at:" -ForegroundColor Red
    Write-Host "  $codex" -ForegroundColor Red
    Write-Host "  Run: npm install -g @openai/codex@0.112.0" -ForegroundColor Yellow
    exit 1
}
if (-not (Test-Path $wslExe)) {
    Write-Host "  ERROR: WSL not found." -ForegroundColor Red
    exit 1
}
# ── Start llama-server (unless skipped) ──────────────────────
if (-not $SkipServerStart) {
    Write-Host "  Starting llama-server ($Model)..." -ForegroundColor Yellow
    Start-Process $wslExe -ArgumentList @("-e","bash","-c","pkill -f llama-server 2>/dev/null || true; sleep 1") -NoNewWindow -Wait
    $modelFileMap = @{
        "9B-Q4" = "unsloth/Qwen3.5-9B-GGUF/Qwen3.5-9B-UD-Q4_K_XL.gguf"
        "9B-Q6" = "unsloth/Qwen3.5-9B-GGUF/Qwen3.5-9B-UD-Q6_K_XL.gguf"
        "35B"   = "unsloth/Qwen3.5-35B-A3B-GGUF/Qwen3.5-35B-A3B-UD-Q3_K_XL.gguf"
    }
    $modelFile     = $modelFileMap[$Model]
    $scriptPath    = "$wslHome/qwen3.5/start_server_tmp.sh"
    $winScriptPath = "\\wsl$\Ubuntu$scriptPath"
    $templatePath  = Join-Path $scriptDir "server_template.sh"
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $tmpl      = [System.IO.File]::ReadAllText($templatePath)
    $tmpl      = $tmpl.Replace("MODEL_FILE",     $modelFile)
    $tmpl      = $tmpl.Replace("MODEL_ALIAS",    $modelAlias)
    $tmpl      = $tmpl.Replace("TEMP_VALUE",     "0.6")
    $tmpl      = $tmpl.Replace("PRESENCE_VALUE", "0.0")
    [System.IO.File]::WriteAllText($winScriptPath, $tmpl, $utf8NoBom)
    Start-Process $wslExe -ArgumentList "-e","chmod","+x",$scriptPath -NoNewWindow -Wait
    $wtPath = (Get-Command wt -ErrorAction SilentlyContinue)?.Source
    if ($wtPath) {
        Start-Process "wt.exe" -ArgumentList "-- wsl.exe bash $scriptPath"
    } else {
        Start-Process "cmd.exe" -ArgumentList "/c wsl.exe bash $scriptPath"
    }
    $waitSecs = if ($Model -eq "35B") { 30 } elseif ($Model -eq "9B-Q6") { 15 } else { 10 }
    Write-Host "  Waiting for server to load (~$waitSecs sec)..." -ForegroundColor Yellow
    Start-Sleep -Seconds $waitSecs
    $serverUp = $false
    for ($i = 1; $i -le 18; $i++) {
        try {
            Invoke-WebRequest -Uri "http://localhost:8001/health" -TimeoutSec 3 -ErrorAction Stop | Out-Null
            $serverUp = $true; break
        } catch {
            Write-Host "  Still loading... ($i/18)" -ForegroundColor DarkYellow
            Start-Sleep -Seconds 5
        }
    }
    if (-not $serverUp) {
        Write-Host "  ERROR: llama-server did not come up after 90 seconds." -ForegroundColor Red
        exit 1
    }
    Write-Host "  Server UP at http://localhost:8001" -ForegroundColor Green
}
else {
    Write-Host "  -SkipServerStart -- assuming server already running." -ForegroundColor DarkGray
    try {
        Invoke-WebRequest -Uri "http://localhost:8001/health" -TimeoutSec 3 -ErrorAction Stop | Out-Null
        Write-Host "  Server confirmed UP." -ForegroundColor Green
    } catch {
        Write-Host "  WARNING: Server not responding on port 8001!" -ForegroundColor Red
        $go = Read-Host "  Continue anyway? (y/n)"
        if ($go -ne "y") { exit 1 }
    }
}
# ── Run codex headlessly via stdin ────────────────────────────
$env:OPENAI_BASE_URL = "http://localhost:8001/v1"
$env:OPENAI_API_KEY  = "sk-local-qwen"
Write-Host ""
Write-Host "  Launching codex exec --full-auto ..." -ForegroundColor Cyan
Write-Host "  Model: $modelAlias" -ForegroundColor DarkGray
Write-Host "  Output logging to: $logFile" -ForegroundColor DarkGray
Write-Host "  Started: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor DarkGray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
$startTime = Get-Date
# Pipe prompt via stdin -- codex reads from stdin when prompt arg is "-"
# This avoids Windows command-line length limits entirely
$resolvedPrompt | & $codex exec `
    --full-auto `
    --model $modelAlias `
    -C $WorkDir `
    --output-last-message $resultFile `
    - 2>&1 | Tee-Object -FilePath $logFile
$exitCode = $LASTEXITCODE
$elapsed  = (Get-Date) - $startTime
# ── Summary ───────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Run complete" -ForegroundColor Cyan
Write-Host "  Exit code:  $exitCode" -ForegroundColor $(if ($exitCode -eq 0) { "Green" } else { "Red" })
Write-Host "  Duration:   $([math]::Floor($elapsed.TotalMinutes))m $($elapsed.Seconds)s" -ForegroundColor White
Write-Host "  Log:        $logFile" -ForegroundColor Gray
Write-Host "  Result:     $resultFile" -ForegroundColor Gray
Write-Host "  Prompt:     $promptLog" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
if (Test-Path $resultFile) {
    Write-Host "  Final agent message:" -ForegroundColor Yellow
    Write-Host ""
    Get-Content $resultFile | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
    Write-Host ""
}
exit $exitCode
