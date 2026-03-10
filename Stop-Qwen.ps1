# ============================================================
# Stop-Qwen.ps1
# Shuts down Qwen - kill server only, or full WSL shutdown
# ============================================================
$wslExe = "$env:SystemRoot\System32\wsl.exe"
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Qwen3.5 -- Shutdown & Cleanup" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Kill server only  (free VRAM, keep WSL running)" -ForegroundColor White
Write-Host "  2. Shutdown WSL      (free VRAM + stop WSL entirely)" -ForegroundColor White
Write-Host "  3. Cancel" -ForegroundColor DarkGray
Write-Host ""
$choice = Read-Host "  Choose (1/2/3)"
if ($choice -eq "1") {
    Write-Host ""
    Write-Host "  Killing llama-server via taskkill..." -ForegroundColor Yellow
    # Find and kill any wsl processes running llama-server via Windows taskkill
    # llama-server runs as a child of wsl.exe - kill by image name pattern
    $procs = Get-Process | Where-Object { $_.Name -like "*llama*" -or $_.MainWindowTitle -like "*llama*" }
    if ($procs) {
        $procs | ForEach-Object {
            Write-Host "  Killing PID $($_.Id) ($($_.Name))..." -ForegroundColor Yellow
            Stop-Process -Id $_.Id -Force
        }
        Write-Host "  Process killed." -ForegroundColor Green
    } else {
        Write-Host "  No llama process found in Windows process list." -ForegroundColor Yellow
        Write-Host "  The server runs inside WSL -- close its terminal window manually." -ForegroundColor Yellow
    }
    # Clean up temp file via PowerShell UNC path - no bash needed
    $tmpFile = "\\wsl$\Ubuntu\home\m_ren\qwen3.5\start_server_tmp.sh"
    if (Test-Path $tmpFile) {
        Remove-Item $tmpFile -Force
        Write-Host "  Temp script cleaned up." -ForegroundColor Green
    }
} elseif ($choice -eq "2") {
    Write-Host ""
    Write-Host "  Shutting down WSL..." -ForegroundColor Yellow
    & $wslExe --shutdown
    Start-Sleep -Seconds 3
    # Clean up temp file (WSL is down so UNC path won't work - skip)
    Write-Host "  WSL stopped. VRAM fully released." -ForegroundColor Green
    Write-Host "  WSL restarts automatically next time you need it." -ForegroundColor DarkGray
} else {
    Write-Host ""
    Write-Host "  Cancelled." -ForegroundColor Gray
}
# Clear env vars either way
Write-Host ""
Write-Host "  Clearing environment variables..." -ForegroundColor Yellow
$env:ANTHROPIC_BASE_URL = ""
$env:ANTHROPIC_API_KEY  = ""
$env:ANTHROPIC_MODEL    = ""
$env:OPENAI_BASE_URL    = ""
$env:OPENAI_API_KEY     = ""
$env:OPENAI_MODEL       = ""
$env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = ""
Write-Host "  Environment cleared." -ForegroundColor Green
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Done!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"
