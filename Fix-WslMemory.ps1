# ============================================================
# Fix-WslMemory.ps1
# Gives WSL2 more RAM so llama.cpp can compile without OOM
# Creates/updates C:\Users\<you>\.wslconfig
# ============================================================
$wslConfig = "$env:USERPROFILE\.wslconfig"
$content = @"
[wsl2]
memory=24GB        # Give WSL 24GB of your 32GB (leaves 8GB for Windows)
swap=8GB           # Extra swap as a safety net during compilation
processors=8       # Use 8 CPU threads (adjust down if your CPU has fewer)
"@
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Configuring WSL2 memory limits" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
if (Test-Path $wslConfig) {
    Write-Host "  Existing .wslconfig found ΓÇö backing up to .wslconfig.bak" -ForegroundColor Yellow
    Copy-Item $wslConfig "$wslConfig.bak"
}
Set-Content -Path $wslConfig -Value $content
Write-Host "  Written: $wslConfig" -ForegroundColor Green
Write-Host ""
Write-Host "  Config applied:" -ForegroundColor White
Get-Content $wslConfig | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
Write-Host ""
Write-Host "  Shutting down WSL to apply new memory settings..." -ForegroundColor Yellow
& "$env:SystemRoot\System32\wsl.exe" --shutdown
Start-Sleep -Seconds 3
Write-Host "  WSL shutdown complete." -ForegroundColor Green
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Done! Now open WSL and run the build with limited jobs:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  cd ~/qwen3.5" -ForegroundColor White
Write-Host "  rm -rf llama.cpp/build" -ForegroundColor White
Write-Host "  cmake llama.cpp -B llama.cpp/build -DBUILD_SHARED_LIBS=OFF -DGGML_CUDA=ON" -ForegroundColor White
Write-Host "  cmake --build llama.cpp/build --config Release -j 4 --target llama-cli llama-server llama-gguf-split" -ForegroundColor White
Write-Host "  cp llama.cpp/build/bin/llama-* llama.cpp/" -ForegroundColor White
Write-Host ""
Write-Host "  The key change is '-j 4' instead of '-j' (unlimited)." -ForegroundColor Yellow
Write-Host "  This limits parallel nvcc processes so you don't OOM." -ForegroundColor Yellow
Write-Host "  It will take ~15-25 mins but will actually finish!" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"
