# ============================================================
# Update-Superpowers.ps1
# Pulls latest obra/superpowers for both Codex and OpenCode.
#
# Usage:
#   .\Update-Superpowers.ps1
# ============================================================
$wslHome = "\\wsl$\Ubuntu\home\m_ren"
$wslUser = "m_ren"
$wslExe  = "$env:SystemRoot\System32\wsl.exe"
function Wsl($cmd) {
    $tmp    = "\\wsl$\Ubuntu\tmp\sp_update_out.txt"
    $wslTmp = "/tmp/sp_update_out.txt"
    Start-Process $wslExe -ArgumentList "-u","$wslUser","-e","bash","-c","($cmd) > $wslTmp 2>&1" -NoNewWindow -Wait
    Start-Sleep -Milliseconds 300
    if (Test-Path $tmp) {
        $out = Get-Content $tmp -Raw
        Remove-Item $tmp -ErrorAction SilentlyContinue
        return $out
    }
    return ""
}
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Update-Superpowers.ps1" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
foreach ($pair in @(
    @{ Label = "Codex";    Path = "~/.codex/superpowers" },
    @{ Label = "OpenCode"; Path = "~/.config/opencode/superpowers" }
)) {
    Write-Host "  Updating $($pair.Label) superpowers..." -ForegroundColor Yellow
    $winPath = $pair.Path -replace "~", "\\wsl$\Ubuntu\home\m_ren"
    if (Test-Path "$winPath\.git") {
        $out = Wsl "cd $($pair.Path) && git pull"
        Write-Host "  $($out.Trim())" -ForegroundColor Gray
        Write-Host "  $($pair.Label) up to date." -ForegroundColor Green
    } else {
        Write-Host "  $($pair.Label) not installed. Run Install-Superpowers.ps1 first." -ForegroundColor Red
    }
    Write-Host ""
}
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Done. Restart OpenCode to pick up any skill changes." -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
