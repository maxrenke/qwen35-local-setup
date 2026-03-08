# ============================================================
# Start-ChatUI.ps1
# Launches Open WebUI ΓÇö a ChatGPT-style browser interface
# that connects to your local Qwen3.5-9B llama-server
#
# First run: installs Open WebUI via pip in WSL (takes ~2 min)
# After that: launches instantly
#
# Usage:
#   .\Start-ChatUI.ps1
#
# Requires: llama-server already running (Start-WslServer.ps1)
# ============================================================
$wslExe = "$env:SystemRoot\System32\wsl.exe"
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Qwen3.5 Chat UI Launcher" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
# --- Check server is up first ---
Write-Host ""
try {
    Invoke-WebRequest -Uri "http://localhost:8001/health" -TimeoutSec 3 -ErrorAction Stop | Out-Null
    Write-Host "  llama-server: UP on http://localhost:8001" -ForegroundColor Green
} catch {
    Write-Host "  WARNING: llama-server is not responding!" -ForegroundColor Red
    Write-Host "  Start it first:" -ForegroundColor Yellow
    Write-Host "    .\Start-WslServer.ps1 -Mode chat" -ForegroundColor Gray
    Write-Host ""
    $continue = Read-Host "  Continue anyway? (y/n)"
    if ($continue -ne "y") { exit 1 }
}
# --- Install Open WebUI in WSL if not already installed ---
Write-Host ""
Write-Host "  Checking if Open WebUI is installed in WSL..." -ForegroundColor Yellow
$checkCmd = "pip show open-webui 2>/dev/null | grep -c 'Name: open-webui'"
$installed = & $wslExe -e bash -c $checkCmd 2>$null
if ($installed -ne "1") {
    Write-Host "  Installing Open WebUI (this takes ~2-5 minutes, once only)..." -ForegroundColor Yellow
    Write-Host ""
    # Install in a subshell so errors don't crash the script
    & $wslExe -e bash -c "pip install open-webui --break-system-packages --quiet"
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "  pip install failed. Trying with --user flag..." -ForegroundColor Yellow
        & $wslExe -e bash -c "pip install open-webui --user --quiet"
    }
    Write-Host "  Open WebUI installed!" -ForegroundColor Green
} else {
    Write-Host "  Open WebUI already installed." -ForegroundColor Green
}
# --- Launch Open WebUI in a new WSL terminal ---
Write-Host ""
Write-Host "  Launching Open WebUI on http://localhost:8080..." -ForegroundColor Yellow
Write-Host "  Pointing at local llama-server on http://localhost:8001" -ForegroundColor Gray
Write-Host ""
$launchCmd = "OPENAI_API_BASE_URL='http://localhost:8001/v1' OPENAI_API_KEY='sk-local-qwen' open-webui serve --port 8080"
$wtPath = (Get-Command wt -ErrorAction SilentlyContinue)?.Source
if ($wtPath) {
    Start-Process "wt.exe" -ArgumentList "wsl.exe -e bash -c `"$launchCmd`""
} else {
    Start-Process "cmd.exe" -ArgumentList "/c wsl.exe -e bash -c `"$launchCmd`""
}
# Wait for Open WebUI to start
Write-Host "  Waiting for Open WebUI to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 6
$maxRetries = 8
for ($i = 1; $i -le $maxRetries; $i++) {
    try {
        Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 3 -ErrorAction Stop | Out-Null
        Write-Host "  Open WebUI is UP!" -ForegroundColor Green
        break
    } catch {
        if ($i -lt $maxRetries) {
            Write-Host "  Still starting... ($i/$maxRetries)" -ForegroundColor Yellow
            Start-Sleep -Seconds 4
        } else {
            Write-Host "  Timeout ΓÇö it may still be loading. Check http://localhost:8080 manually." -ForegroundColor Yellow
        }
    }
}
# Open the browser
Write-Host ""
Write-Host "  Opening browser..." -ForegroundColor Cyan
Start-Process "http://localhost:8080"
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Chat UI running at: http://localhost:8080" -ForegroundColor Green
Write-Host ""
Write-Host "  First time setup in the browser:" -ForegroundColor White
Write-Host "    1. Create a local admin account (any email/password)" -ForegroundColor Gray
Write-Host "    2. Select 'unsloth/Qwen3.5-9B' from the model dropdown" -ForegroundColor Gray
Write-Host "    3. Start chatting!" -ForegroundColor Gray
Write-Host ""
Write-Host "  To stop: close the Open WebUI terminal window" -ForegroundColor DarkGray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit this launcher"
