# ============================================================
# Start-Tonight.ps1
# One-command launcher for overnight agent runs.
#
# Usage:
#   .\Start-Tonight.ps1                       # list all projects
#   .\Start-Tonight.ps1 -Project pob          # run a project
#   .\Start-Tonight.ps1 -Project osv -Model 35B
#   .\Start-Tonight.ps1 -Project osv -Superpowers
# ============================================================
param(
    [ValidateSet("pob", "psscripts", "osv", "audit", "devenv")]
    [string]$Project = "",
    [ValidateSet("9B-Q4", "9B-Q6", "35B")]
    [string]$Model = "9B-Q6",
    [switch]$Superpowers
)
$scriptDir = Split-Path $MyInvocation.MyCommand.Path
# ΓöÇΓöÇ Project definitions ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
$projects = [ordered]@{
    "pob" = @{
        Label       = "pob-mcp"
        Description = "Add unit tests for bossReadiness, leveling & skillGem handlers. PR to ianderse/pob-mcp."
        PromptFile  = "C:\Users\m_ren\repos\pob-mcp\prompt.txt"
        WorkDir     = "C:\Users\m_ren\repos\pob-mcp"
        Branch      = "agent/test-coverage-phase1"
        Notes       = "pob-mcp\AGENT_RUN_NOTES.md  |  git log agent/test-coverage-phase1"
    }
    "psscripts" = @{
        Label       = "powershell-scripts"
        Description = "Clarify duplicate scripts, add -WhatIf to destructive ops, improve ROM support, add Update-PoB.ps1."
        PromptFile  = "C:\Users\m_ren\repos\powershell-scripts\prompt.txt"
        WorkDir     = "C:\Users\m_ren\repos\powershell-scripts"
        Branch      = "main (direct commits)"
        Notes       = "powershell-scripts\AGENT_RUN_NOTES.md  |  git log main -10"
    }
    "osv" = @{
        Label       = "osv-vulnerability-scanner"
        Description = "Write full test suite (currently zero tests), add --requirements file scanning, ecosystem support."
        PromptFile  = "C:\Users\m_ren\repos\osv-vulnerability-scanner\prompt.txt"
        WorkDir     = "C:\Users\m_ren\repos\osv-vulnerability-scanner"
        Branch      = "agent/improvements"
        Notes       = "osv-vulnerability-scanner\AGENT_RUN_NOTES.md  |  git log agent/improvements"
    }
    "audit" = @{
        Label       = "audit-packages-tool"
        Description = "Fill 90% coverage gap (auditor/reporter/cli untested), add winget support for Windows."
        PromptFile  = "C:\Users\m_ren\repos\audit_packages_tool\prompt.txt"
        WorkDir     = "C:\Users\m_ren\repos\audit_packages_tool"
        Branch      = "agent/improvements"
        Notes       = "audit_packages_tool\AGENT_RUN_NOTES.md  |  git log agent/improvements"
    }
    "devenv" = @{
        Label       = "dev-environment-setup"
        Description = "Make setup.sh idempotent, add --dry-run/--force, per-component flags (--no-fish etc)."
        PromptFile  = "C:\Users\m_ren\repos\dev-environment-setup\prompt.txt"
        WorkDir     = "C:\Users\m_ren\repos\dev-environment-setup"
        Branch      = "master (direct commits)"
        Notes       = "dev-environment-setup\AGENT_RUN_NOTES.md  |  git log master -10"
    }
}
# ΓöÇΓöÇ No project given: print the menu and exit ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
if (-not $Project) {
    Write-Host ""
    Write-Host "  Start-Tonight.ps1 ΓÇö Available Projects" -ForegroundColor Cyan
    Write-Host "  ΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöü" -ForegroundColor DarkGray
    foreach ($key in $projects.Keys) {
        $p = $projects[$key]
        Write-Host ("  -{0,-12}" -f $key) -ForegroundColor Yellow -NoNewline
        Write-Host $p.Label -ForegroundColor White -NoNewline
        Write-Host "  [$($p.Branch)]" -ForegroundColor DarkGray
        Write-Host ("  {0,-14}" -f "") -NoNewline
        Write-Host $p.Description -ForegroundColor DarkGray
        Write-Host ""
    }
    Write-Host "  Usage:" -ForegroundColor Cyan
    Write-Host "    .\Start-Tonight.ps1 -Project <name>" -ForegroundColor White
    Write-Host "    .\Start-Tonight.ps1 -Project osv -Model 35B" -ForegroundColor White
    Write-Host "    .\Start-Tonight.ps1 -Project pob -Superpowers" -ForegroundColor White
    Write-Host ""
    exit 0
}
# ΓöÇΓöÇ Project selected: run it ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
$p = $projects[$Project]
Write-Host ""
Write-Host "  ΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöü" -ForegroundColor DarkGray
Write-Host "  Tonight's Agent Run" -ForegroundColor Cyan
Write-Host "  Project:     $($p.Label)" -ForegroundColor White
Write-Host "  Model:       $Model" -ForegroundColor White
Write-Host "  Superpowers: $(if ($Superpowers) { 'ON' } else { 'off' })" -ForegroundColor $(if ($Superpowers) { 'Magenta' } else { 'DarkGray' })
Write-Host "  Branch:      $($p.Branch)" -ForegroundColor White
Write-Host "  WorkDir:     $($p.WorkDir)" -ForegroundColor White
Write-Host "  ΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöüΓöü" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Server opens in a background window. This terminal runs the agent." -ForegroundColor DarkGray
Write-Host "  In the morning: $($p.Notes)" -ForegroundColor DarkGray
Write-Host ""
$agentScript = Join-Path $scriptDir "Start-OvernightAgent.ps1"
if (-not (Test-Path $agentScript)) {
    Write-Host "  ERROR: Start-OvernightAgent.ps1 not found at $agentScript" -ForegroundColor Red
    exit 1
}
$agentArgs = @{
    PromptFile = $p.PromptFile
    WorkDir    = $p.WorkDir
    Model      = $Model
}
if ($Superpowers) { $agentArgs["Superpowers"] = $true }
& $agentScript @agentArgs
