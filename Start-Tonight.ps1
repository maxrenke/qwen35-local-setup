# ============================================================
# Start-Tonight.ps1
# One-command launcher for overnight agent runs.
# Starts the model server, then fires the agent at a chosen project.
#
# Usage:
#   .\Start-Tonight.ps1 -Project pob          # pob-mcp test coverage
#   .\Start-Tonight.ps1 -Project psscripts    # powershell-scripts improvements
#   .\Start-Tonight.ps1 -Project osv          # osv-vulnerability-scanner
#   .\Start-Tonight.ps1 -Project audit        # audit-packages-tool
#   .\Start-Tonight.ps1 -Project devenv       # dev-environment-setup
#   .\Start-Tonight.ps1 -Project pob -Model 35B
#   .\Start-Tonight.ps1 -Project osv -Superpowers
#
# The server starts in a background window automatically.
# This script stays in one terminal -- no second window needed.
# ============================================================
param(
    [Parameter(Mandatory)]
    [ValidateSet("pob", "psscripts", "osv", "audit", "devenv")]
    [string]$Project,
    [ValidateSet("9B-Q4", "9B-Q6", "35B")]
    [string]$Model = "9B-Q6",
    [switch]$Superpowers
)
$scriptDir = Split-Path $MyInvocation.MyCommand.Path
# ΓöÇΓöÇ Project definitions ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
$projects = @{
    "pob" = @{
        Label      = "pob-mcp (test coverage)"
        PromptFile = "C:\Users\m_ren\repos\pob-mcp\prompt.txt"
        WorkDir    = "C:\Users\m_ren\repos\pob-mcp"
        Branch     = "agent/test-coverage-phase1"
        Notes      = "pob-mcp\AGENT_RUN_NOTES.md | git log agent/test-coverage-phase1"
    }
    "psscripts" = @{
        Label      = "powershell-scripts (improvements)"
        PromptFile = "C:\Users\m_ren\repos\powershell-scripts\prompt.txt"
        WorkDir    = "C:\Users\m_ren\repos\powershell-scripts"
        Branch     = "main (direct commits)"
        Notes      = "powershell-scripts\AGENT_RUN_NOTES.md | git log main -10"
    }
    "osv" = @{
        Label      = "osv-vulnerability-scanner (tests + features)"
        PromptFile = "C:\Users\m_ren\repos\osv-vulnerability-scanner\prompt.txt"
        WorkDir    = "C:\Users\m_ren\repos\osv-vulnerability-scanner"
        Branch     = "agent/improvements"
        Notes      = "osv-vulnerability-scanner\AGENT_RUN_NOTES.md | git log agent/improvements"
    }
    "audit" = @{
        Label      = "audit-packages-tool (tests + winget support)"
        PromptFile = "C:\Users\m_ren\repos\audit_packages_tool\prompt.txt"
        WorkDir    = "C:\Users\m_ren\repos\audit_packages_tool"
        Branch     = "agent/improvements"
        Notes      = "audit_packages_tool\AGENT_RUN_NOTES.md | git log agent/improvements"
    }
    "devenv" = @{
        Label      = "dev-environment-setup (idempotency + flags)"
        PromptFile = "C:\Users\m_ren\repos\dev-environment-setup\prompt.txt"
        WorkDir    = "C:\Users\m_ren\repos\dev-environment-setup"
        Branch     = "master (direct commits)"
        Notes      = "dev-environment-setup\AGENT_RUN_NOTES.md | git log master -10"
    }
}
$p = $projects[$Project]
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Tonight's Agent Run" -ForegroundColor Cyan
Write-Host "  Project:     $($p.Label)" -ForegroundColor White
Write-Host "  Model:       $Model" -ForegroundColor White
Write-Host "  Superpowers: $(if ($Superpowers) { 'ON' } else { 'off' })" -ForegroundColor $(if ($Superpowers) { 'Magenta' } else { 'DarkGray' })
Write-Host "  Branch:      $($p.Branch)" -ForegroundColor White
Write-Host "  WorkDir:     $($p.WorkDir)" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  The server will open in a background window." -ForegroundColor DarkGray
Write-Host "  This terminal runs the agent. One window is all you need." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  In the morning check:" -ForegroundColor DarkGray
Write-Host "  $($p.Notes)" -ForegroundColor DarkGray
Write-Host ""
# ΓöÇΓöÇ Build the agent args and call Start-OvernightAgent.ps1 ΓöÇΓöÇΓöÇ
$agentScript = Join-Path $scriptDir "Start-OvernightAgent.ps1"
if (-not (Test-Path $agentScript)) {
    Write-Host "  ERROR: Start-OvernightAgent.ps1 not found at $agentScript" -ForegroundColor Red
    exit 1
}
$agentArgs = @(
    "-PromptFile", $p.PromptFile,
    "-WorkDir",    $p.WorkDir,
    "-Model",      $Model
)
if ($Superpowers) { $agentArgs += "-Superpowers" }
& $agentScript @agentArgs
