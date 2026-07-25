# ============================================================
# Install-Superpowers.ps1
# Installs obra/superpowers for both Codex and OpenCode in WSL.
#
# What it does:
#   - Clones superpowers into the right WSL locations for Codex and OpenCode
#   - Wires up the OpenCode plugin symlink
#   - Patches ~/.codex/AGENTS.md to inject the bootstrap instruction
#   - Verifies the install by running the Codex bootstrap command
#
# Run once. Re-running is safe (uses git pull if already cloned).
#
# Usage:
#   .\Install-Superpowers.ps1
# ============================================================
$wslHome  = "\\wsl$\Ubuntu\home\m_ren"
$wslUser  = "m_ren"
$wslExe   = "$env:SystemRoot\System32\wsl.exe"
function Wsl($cmd) {
    # Run a bash command in WSL, capture and return output
    $tmp = "\\wsl$\Ubuntu\tmp\sp_install_out.txt"
    $wslTmp = "/tmp/sp_install_out.txt"
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
Write-Host "  Install-Superpowers.ps1" -ForegroundColor Cyan
Write-Host "  obra/superpowers -> Codex + OpenCode in WSL" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
# ΓöÇΓöÇ Sanity checks ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
if (-not (Test-Path $wslHome)) {
    Write-Host "  ERROR: WSL home not found at $wslHome" -ForegroundColor Red
    Write-Host "  Make sure WSL (Ubuntu) is running." -ForegroundColor Yellow
    exit 1
}
$gitCheck = Wsl "which git && git --version"
if ($gitCheck -notmatch "git version") {
    Write-Host "  ERROR: git not found in WSL." -ForegroundColor Red
    Write-Host "  Run in WSL: sudo apt-get install -y git" -ForegroundColor Yellow
    exit 1
}
Write-Host "  git: $($gitCheck.Trim())" -ForegroundColor Green
# ΓöÇΓöÇ 1. Install for Codex ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
Write-Host ""
Write-Host "  [1/4] Installing superpowers for Codex..." -ForegroundColor Yellow
$codexSuperpowers = "$wslHome\.codex\superpowers"
if (Test-Path "$codexSuperpowers\.git") {
    Write-Host "        Already cloned -- pulling latest..." -ForegroundColor DarkGray
    $out = Wsl "cd ~/.codex/superpowers && git pull"
    Write-Host "        $($out.Trim())" -ForegroundColor Gray
} else {
    Write-Host "        Cloning obra/superpowers -> ~/.codex/superpowers ..." -ForegroundColor DarkGray
    $out = Wsl "mkdir -p ~/.codex/superpowers && git clone https://github.com/obra/superpowers.git ~/.codex/superpowers"
    Write-Host "        $($out.Trim())" -ForegroundColor Gray
}
# Create personal skills dir
Wsl "mkdir -p ~/.codex/skills" | Out-Null
Write-Host "        ~/.codex/skills/ ready" -ForegroundColor DarkGray
# Patch AGENTS.md
$agentsMdPath = "$wslHome\.codex\AGENTS.md"
$superPowersBlock = @"
## Superpowers System
<EXTREMELY_IMPORTANT>
You have superpowers. Superpowers teach you new skills and capabilities. RIGHT NOW run: ``~/.codex/superpowers/.codex/superpowers-codex bootstrap`` and follow the instructions it returns.
</EXTREMELY_IMPORTANT>
"@
if (-not (Test-Path $agentsMdPath)) {
    # Create fresh AGENTS.md
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($agentsMdPath, $superPowersBlock.TrimStart(), $utf8NoBom)
    Write-Host "        Created ~/.codex/AGENTS.md with superpowers block" -ForegroundColor Green
} else {
    $existing = Get-Content $agentsMdPath -Raw
    if ($existing -match "superpowers-codex bootstrap") {
        Write-Host "        ~/.codex/AGENTS.md already has superpowers block -- skipping" -ForegroundColor DarkGray
    } else {
        $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
        [System.IO.File]::WriteAllText($agentsMdPath, $existing + "`n" + $superPowersBlock, $utf8NoBom)
        Write-Host "        Appended superpowers block to ~/.codex/AGENTS.md" -ForegroundColor Green
    }
}
Write-Host "  [1/4] Codex install done." -ForegroundColor Green
# ΓöÇΓöÇ 2. Install for OpenCode ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
Write-Host ""
Write-Host "  [2/4] Installing superpowers for OpenCode..." -ForegroundColor Yellow
$opencodeSuperpowers = "$wslHome\.config\opencode\superpowers"
if (Test-Path "$opencodeSuperpowers\.git") {
    Write-Host "        Already cloned -- pulling latest..." -ForegroundColor DarkGray
    $out = Wsl "cd ~/.config/opencode/superpowers && git pull"
    Write-Host "        $($out.Trim())" -ForegroundColor Gray
} else {
    Write-Host "        Cloning obra/superpowers -> ~/.config/opencode/superpowers ..." -ForegroundColor DarkGray
    $out = Wsl "mkdir -p ~/.config/opencode/superpowers && git clone https://github.com/obra/superpowers.git ~/.config/opencode/superpowers"
    Write-Host "        $($out.Trim())" -ForegroundColor Gray
}
Write-Host "  [2/4] OpenCode clone done." -ForegroundColor Green
# ΓöÇΓöÇ 3. Wire up OpenCode plugin symlink ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
Write-Host ""
Write-Host "  [3/4] Wiring OpenCode plugin symlink..." -ForegroundColor Yellow
$out = Wsl @"
mkdir -p ~/.config/opencode/plugin
ln -sf ~/.config/opencode/superpowers/.opencode/plugin/superpowers.js ~/.config/opencode/plugin/superpowers.js
echo "symlink: \$(readlink ~/.config/opencode/plugin/superpowers.js)"
ls -la ~/.config/opencode/plugin/
"@
Write-Host "        $($out.Trim() -replace "`n", "`n        ")" -ForegroundColor Gray
# Create personal OpenCode skills dir
Wsl "mkdir -p ~/.config/opencode/skills" | Out-Null
Write-Host "        ~/.config/opencode/skills/ ready" -ForegroundColor DarkGray
Write-Host "  [3/4] OpenCode plugin wired." -ForegroundColor Green
# ΓöÇΓöÇ 4. Verify Codex bootstrap ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
Write-Host ""
Write-Host "  [4/4] Verifying Codex bootstrap command..." -ForegroundColor Yellow
$out = Wsl "~/.codex/superpowers/.codex/superpowers-codex bootstrap 2>&1 | head -30"
if ($out -match "skill" -or $out -match "superpower" -or $out -match "bootstrap") {
    Write-Host "        Bootstrap output looks good:" -ForegroundColor Green
} else {
    Write-Host "        Bootstrap output (verify manually):" -ForegroundColor Yellow
}
$out.Trim() -split "`n" | ForEach-Object { Write-Host "        $_" -ForegroundColor Gray }
# ΓöÇΓöÇ Summary ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Codex:    ~/.codex/superpowers/" -ForegroundColor White
Write-Host "            ~/.codex/AGENTS.md (bootstrap injected)" -ForegroundColor Gray
Write-Host "            ~/.codex/skills/   (personal skills)" -ForegroundColor Gray
Write-Host ""
Write-Host "  OpenCode: ~/.config/opencode/superpowers/" -ForegroundColor White
Write-Host "            ~/.config/opencode/plugin/superpowers.js (symlink)" -ForegroundColor Gray
Write-Host "            ~/.config/opencode/skills/ (personal skills)" -ForegroundColor Gray
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Cyan
Write-Host "    Codex:    superpowers activates automatically via AGENTS.md" -ForegroundColor White
Write-Host "    OpenCode: restart opencode -- ask 'do you have superpowers?'" -ForegroundColor White
Write-Host ""
Write-Host "  Update anytime:" -ForegroundColor Cyan
Write-Host "    .\Update-Superpowers.ps1" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
