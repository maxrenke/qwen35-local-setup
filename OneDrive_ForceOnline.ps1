# ============================================================
# OneDrive_ForceOnline.ps1
# Forces all cloud-only OneDrive placeholder files to download
# Works on PowerShell 5 and 7, parallel via runspace pool
#
# Usage:
#   .\OneDrive_ForceOnline.ps1 -Path "C:\Users\m_ren\OneDrive\GoogleDrive"
#   .\OneDrive_ForceOnline.ps1 -Path "C:\Users\m_ren\OneDrive\GoogleDrive" -Recursive
#   .\OneDrive_ForceOnline.ps1 -Path "C:\Users\m_ren\OneDrive\GoogleDrive" -Recursive -Force
#   .\OneDrive_ForceOnline.ps1 -Path "C:\Users\m_ren\OneDrive\GoogleDrive" -Recursive -WhatIf
#   .\OneDrive_ForceOnline.ps1 -Path "C:\Users\m_ren\OneDrive\GoogleDrive" -Recursive -Workers 32
# ============================================================
param(
    [Parameter(Mandatory=$true)]
    [string]$Path,
    [switch]$Recursive,
    [switch]$Force,
    [switch]$WhatIf,
    [int]$Workers = 16
)
if (-not (Test-Path $Path)) {
    Write-Host "ERROR: Path not found: $Path" -ForegroundColor Red
    exit 1
}
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  OneDrive Force Online" -ForegroundColor Cyan
Write-Host "  Path:      $Path" -ForegroundColor White
Write-Host "  Recursive: $Recursive" -ForegroundColor Gray
Write-Host "  Force:     $Force" -ForegroundColor Gray
Write-Host "  Workers:   $Workers" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Scanning files..." -ForegroundColor Yellow
$getParams = @{ Path = $Path; File = $true; ErrorAction = "SilentlyContinue" }
if ($Recursive) { $getParams.Recurse = $true }
$allFiles = Get-ChildItem @getParams
$offlineFiles = $allFiles | Where-Object {
    ($_.Attributes -band 0x1000) -ne 0 -or
    ($_.Attributes -band 0x400000) -ne 0
}
$targets       = if ($Force) { $allFiles } else { $offlineFiles }
$total         = $targets.Count
$alreadyOnline = $allFiles.Count - $offlineFiles.Count
Write-Host "  Total files scanned:    $($allFiles.Count)" -ForegroundColor White
Write-Host "  Already online:         $alreadyOnline" -ForegroundColor Green
Write-Host "  Placeholders to fetch:  $total" -ForegroundColor Yellow
Write-Host ""
if ($total -eq 0) {
    Write-Host "  Nothing to do -- all files are already online!" -ForegroundColor Green
    exit 0
}
if ($WhatIf) {
    Write-Host "  WhatIf mode -- files that would be downloaded:" -ForegroundColor Cyan
    $targets | Select-Object -First 20 | ForEach-Object { Write-Host "    $($_.FullName)" -ForegroundColor Gray }
    if ($total -gt 20) { Write-Host "    ... and $($total - 20) more" -ForegroundColor DarkGray }
    exit 0
}
Write-Host "  Starting parallel download ($Workers workers)..." -ForegroundColor Yellow
Write-Host "  Watch the OneDrive tray icon for sync activity." -ForegroundColor DarkGray
Write-Host ""
$targetPaths = $targets | Select-Object -ExpandProperty FullName
# --- Runspace pool (works PS5 + PS7) ---
$scriptBlock = {
    param($filePath)
    try {
        & attrib -U $filePath 2>$null
        try {
            $stream = [System.IO.File]::OpenRead($filePath)
            $buf = New-Object byte[] 1
            $stream.Read($buf, 0, 1) | Out-Null
            $stream.Close()
            $stream.Dispose()
        } catch {}
        return "ok"
    } catch {
        return "fail"
    }
}
$pool = [RunspaceFactory]::CreateRunspacePool(1, $Workers)
$pool.Open()
$jobs     = [System.Collections.Generic.List[hashtable]]::new()
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
# Submit all jobs
foreach ($filePath in $targetPaths) {
    $ps = [PowerShell]::Create()
    $ps.RunspacePool = $pool
    [void]$ps.AddScript($scriptBlock).AddArgument($filePath)
    $jobs.Add(@{ PS = $ps; Handle = $ps.BeginInvoke() })
}
Write-Host "  All $total jobs submitted. Waiting for completion..." -ForegroundColor Gray
Write-Host ""
# Poll progress
$done   = 0
$failed = 0
$lastDone = 0
while ($done -lt $total) {
    Start-Sleep -Milliseconds 500
    $done   = ($jobs | Where-Object { $_.Handle.IsCompleted }).Count
    $pct    = [int](($done / $total) * 100)
    $elapsed = $stopwatch.Elapsed.ToString("mm\:ss")
    $rate   = [int]($done / [Math]::Max($stopwatch.Elapsed.TotalSeconds, 1))
    $remaining = if ($rate -gt 0) { [int](($total - $done) / $rate) } else { 0 }
    Write-Progress -Activity "Forcing OneDrive files online" `
                   -Status "$done / $total  ($pct%)  --  ~$rate files/sec  --  ~${remaining}s left" `
                   -PercentComplete $pct
    # Print update every 500 newly completed files
    if (($done - $lastDone) -ge 500) {
        Write-Host "  [$elapsed]  $done/$total  (~$rate files/sec, ~${remaining}s remaining)" -ForegroundColor Gray
        $lastDone = $done
    }
}
# Collect results
foreach ($job in $jobs) {
    $result = $job.PS.EndInvoke($job.Handle)
    if ($result -eq "fail") { $failed++ }
    $job.PS.Dispose()
}
$pool.Close()
$pool.Dispose()
Write-Progress -Activity "Forcing OneDrive files online" -Completed
$stopwatch.Stop()
$elapsed = $stopwatch.Elapsed.ToString("hh\:mm\:ss")
$rate    = [int]($total / [Math]::Max($stopwatch.Elapsed.TotalSeconds, 1))
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Completed in $elapsed" -ForegroundColor Green
Write-Host "  Triggered:      $($total - $failed) / $total" -ForegroundColor Green
Write-Host "  Failed:         $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
Write-Host "  Already online: $alreadyOnline" -ForegroundColor Gray
Write-Host "  Avg rate:       ~$rate files/sec" -ForegroundColor Gray
Write-Host ""
Write-Host "  OneDrive will continue syncing in the background." -ForegroundColor DarkGray
Write-Host "  Watch the tray icon until it shows 'Up to date'." -ForegroundColor DarkGray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
