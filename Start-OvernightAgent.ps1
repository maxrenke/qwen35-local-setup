# ============================================================
# Start-OvernightAgent.ps1
# Starts llama-server + runs opencode headlessly on a task.
#
# Uses opencode run (not codex) -- compatible with llama-server /v1/chat/completions.
# Codex v0.113+ switched to /v1/responses which llama-server does not support.
#
# Usage:
#   .\Start-OvernightAgent.ps1 -Prompt "build me a thing"
#   .\Start-OvernightAgent.ps1 -PromptFile ".\prompt.txt"
#   .\Start-OvernightAgent.ps1 -PromptFile ".\prompt.txt" -Model 9B-Q6
#   .\Start-OvernightAgent.ps1 -PromptFile ".\prompt.txt" -WorkDir "C:\repos\my-project"
#   .\Start-OvernightAgent.ps1 -PromptFile ".\prompt.txt" -Superpowers
#
# Prompt resolution order:
#   1. -Prompt string (if provided)
#   2. -PromptFile path (if provided)
#   3. prompt.txt in the same directory as this script (auto-detected)
#
# Output:
#   Logs written to .\logs\<timestamp>\ next to this script
#   Final agent output in logs\<timestamp>\agent.log
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
# ΓöÇΓöÇ Paths ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
# opencode uses /v1/chat/completions -- fully compatible with llama-server
$opencode = "$env:APPDATA\npm\node_modules\opencode-ai\node_modules\opencode-windows-x64\bin\opencode.exe"
$wslExe   = "$env:SystemRoot\System32\wsl.exe"
$wslUser  = "m_ren"
$wslHome  = "/home/$wslUser"
$logsRoot = Join-Path $scriptDir "logs"
$runStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logDir   = Join-Path $logsRoot $runStamp
# opencode model format: provider/model-id  (provider = "qwen" per opencode.json)
$aliasMap = @{
    "9B-Q4" = "qwen/unsloth/Qwen3.5-9B-Q4"
    "9B-Q6" = "qwen/unsloth/Qwen3.5-9B-Q6"
    "35B"   = "qwen/unsloth/Qwen3.5-35B"
}
$modelAlias = $aliasMap[$Model]
# ΓöÇΓöÇ Resolve prompt ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
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
        Write-Host ""
        Write-Host "  Options:" -ForegroundColor Yellow
        Write-Host "    1. Pass a prompt:    .\Start-OvernightAgent.ps1 -Prompt 'do a thing'" -ForegroundColor Gray
        Write-Host "    2. Pass a file:      .\Start-OvernightAgent.ps1 -PromptFile .\prompt.txt" -ForegroundColor Gray
        Write-Host "    3. Drop a file:      create prompt.txt next to this script" -ForegroundColor Gray
        Write-Host ""
        exit 1
    }
}
$resolvedPrompt = $resolvedPrompt.Trim()
# ΓöÇΓöÇ Optionally prepend superpowers bootstrap ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
if ($Superpowers) {
    $spInstalled = Test-Path "\\wsl$\Ubuntu\home\m_ren\.codex\superpowers\.git"
    if (-not $spInstalled) {
        Write-Host ""
        Write-Host "  ERROR: -Superpowers flag set but superpowers not installed." -ForegroundColor Red
        Write-Host "  Run: .\Install-Superpowers.ps1 first." -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
    $spPreamble = @"
Before doing ANYTHING else: run ``~/.codex/superpowers/.codex/superpowers-codex bootstrap`` and follow all the instructions it returns. Load and apply all relevant skills before proceeding with the task below.
---
"@
    $resolvedPrompt = $spPreamble + $resolvedPrompt
    $promptSource   = "$promptSource [+superpowers]"
}
# ΓöÇΓöÇ Resolve working directory ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
if ($WorkDir -eq "") { $WorkDir = $scriptDir }
if (-not (Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir | Out-Null }
# ΓöÇΓöÇ Create log dir ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$logFile   = Join-Path $logDir "agent.log"
$promptLog = Join-Path $logDir "prompt_used.txt"
$resolvedPrompt | Out-File -FilePath $promptLog -Encoding UTF8
# ΓöÇΓöÇ Header ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Overnight Agent (opencode)" -ForegroundColor Cyan
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
# ΓöÇΓöÇ Sanity checks ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
if (-not (Test-Path $opencode)) {
    Write-Host "  ERROR: opencode not found at $opencode" -ForegroundColor Red
    Write-Host "  Run: npm install -g opencode-ai" -ForegroundColor Yellow
    exit 1
}
if (-not (Test-Path $wslExe)) {
    Write-Host "  ERROR: WSL not found." -ForegroundColor Red
    exit 1
}
# ΓöÇΓöÇ Start llama-server (unless skipped) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
if (-not $SkipServerStart) {
    Write-Host "  Starting llama-server ($Model)..." -ForegroundColor Yellow
    # Kill any running server first
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
    $content   = [System.IO.File]::ReadAllText($templatePath)
    $content   = $content.Replace("MODEL_FILE",     $modelFile)
    $content   = $content.Replace("MODEL_ALIAS",    $modelAlias)
    $content   = $content.Replace("TEMP_VALUE",     "0.6")
    $content   = $content.Replace("PRESENCE_VALUE", "0.0")
    [System.IO.File]::WriteAllText($winScriptPath, $content, $utf8NoBom)
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
            $serverUp = $true
            break
        } catch {
            Write-Host "  Still loading... ($i/18)" -ForegroundColor DarkYellow
            Start-Sleep -Seconds 5
        }
    }
    if (-not $serverUp) {
        Write-Host ""
        Write-Host "  ERROR: llama-server did not come up after 90 seconds." -ForegroundColor Red
        Write-Host "  Check the server window for errors." -ForegroundColor Yellow
        exit 1
    }
    Write-Host "  Server UP at http://localhost:8001" -ForegroundColor Green
}
else {
    Write-Host "  -SkipServerStart set -- assuming server already running." -ForegroundColor DarkGray
    try {
        Invoke-WebRequest -Uri "http://localhost:8001/health" -TimeoutSec 3 -ErrorAction Stop | Out-Null
        Write-Host "  Server confirmed UP at http://localhost:8001" -ForegroundColor Green
    } catch {
        Write-Host "  WARNING: Server not responding on port 8001!" -ForegroundColor Red
        $continue = Read-Host "  Continue anyway? (y/n)"
        if ($continue -ne "y") { exit 1 }
    }
}
# ΓöÇΓöÇ Run opencode headlessly ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
Write-Host ""
Write-Host "  Launching opencode run ..." -ForegroundColor Cyan
Write-Host "  Model: $modelAlias" -ForegroundColor DarkGray
Write-Host "  Output logging to: $logFile" -ForegroundColor DarkGray
Write-Host "  Started: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor DarkGray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
$startTime = Get-Date
# Write prompt to a temp file -- pass via -f (file attach) to avoid arg length crashes
# The inline message just tells opencode to read the attached file as its full instructions
$promptTmp = Join-Path $env:TEMP "opencode_prompt_$runStamp.txt"
$resolvedPrompt | Out-File -FilePath $promptTmp -Encoding UTF8 -NoNewline
& $opencode run `
    --model $modelAlias `
    --dir $WorkDir `
    -f $promptTmp `
    "Your full instructions are in the attached file. Read it completely before doing anything." `
    2>&1 | Tee-Object -FilePath $logFile
$exitCode = $LASTEXITCODE
Remove-Item $promptTmp -ErrorAction SilentlyContinue
$endTime = Get-Date
$elapsed = $endTime - $startTime
# ΓöÇΓöÇ Summary ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Run complete" -ForegroundColor Cyan
Write-Host "  Exit code:  $exitCode" -ForegroundColor $(if ($exitCode -eq 0) { "Green" } else { "Red" })
Write-Host "  Duration:   $([math]::Floor($elapsed.TotalMinutes))m $($elapsed.Seconds)s" -ForegroundColor White
Write-Host "  Log:        $logFile" -ForegroundColor Gray
Write-Host "  Prompt:     $promptLog" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
exit $exitCode
