# ============================================================
# Start-ClaudeCode.ps1
# Starts Ollama (if not running) then launches Claude Code
#
# Usage:
#   .\Start-ClaudeCode.ps1              -> local qwen3:8b-32k (default)
#   .\Start-ClaudeCode.ps1 -Cloud       -> Anthropic cloud API
#   .\Start-ClaudeCode.ps1 -Dir C:\foo  -> open in specific directory
#
# Models (edit claude.config.json to change):
#   main        qwen3:8b-32k    (default, best quality)
#   fast        qwen3.5:0.8b-32k (fast subagent/autocomplete)
#   coder-small qwen2.5-coder:1.5b
# ============================================================
param(
    [switch]$Cloud,
    [string]$Dir = ""
)

$OLLAMA_PORT   = 11435
$OLLAMA_HOST   = "127.0.0.1:$OLLAMA_PORT"
$CLAUDE_CMD    = "C:\Users\m_ren\.local\bin\claude.exe"
$HEALTH_URL    = "http://localhost:$OLLAMA_PORT/api/tags"

# ---- helpers ------------------------------------------------
function Write-Banner($msg, $color = "Cyan") {
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor $color
    Write-Host "  $msg" -ForegroundColor $color
    Write-Host ("=" * 60) -ForegroundColor $color
}

function Test-OllamaRunning {
    try {
        $null = Invoke-RestMethod -Uri $HEALTH_URL -TimeoutSec 5 -ErrorAction Stop
        return $true
    } catch { return $false }
}

function Start-OllamaServer {
    Write-Host "  Starting Ollama on port $OLLAMA_PORT..." -ForegroundColor Yellow

    # Launch with explicit env via ProcessStartInfo so OLLAMA_HOST is inherited correctly
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "ollama"
    $pinfo.Arguments = "serve"
    $pinfo.UseShellExecute = $false
    $pinfo.CreateNoWindow = $true
    $pinfo.EnvironmentVariables["OLLAMA_HOST"] = $OLLAMA_HOST
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $pinfo
    $proc.Start() | Out-Null

    # Give it a moment to bind before polling
    Start-Sleep -Seconds 3

    $maxWait = 10
    for ($i = 1; $i -le $maxWait; $i++) {
        if (Test-OllamaRunning) {
            Write-Host "  Ollama ready" -ForegroundColor Green
            return $true
        }
        Write-Host "  Waiting... ($i/$maxWait)" -ForegroundColor DarkGray
        Start-Sleep -Seconds 1
    }
    Write-Host "  ERROR: Ollama failed to start after $($maxWait + 3)s" -ForegroundColor Red
    return $false
}

# ---- sanity checks ------------------------------------------
if (-not (Test-Path $CLAUDE_CMD)) {
    Write-Host "ERROR: claude not found at $CLAUDE_CMD" -ForegroundColor Red
    Write-Host "Run: claude install" -ForegroundColor Yellow
    exit 1
}

# ---- cloud mode ---------------------------------------------
if ($Cloud) {
    Write-Banner "Claude Code -> Anthropic Cloud" "Magenta"
    $existingKey = [System.Environment]::GetEnvironmentVariable("ANTHROPIC_API_KEY", "User")
    if (-not $existingKey) {
        Write-Host "  No ANTHROPIC_API_KEY found." -ForegroundColor Yellow
        Write-Host "  Get yours: https://console.anthropic.com/settings/keys" -ForegroundColor Gray
        $apiKey = Read-Host "  Paste your key (sk-ant-...)"
        if (-not $apiKey) { Write-Host "No key entered." -ForegroundColor Red; exit 1 }
        [System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $apiKey, "User")
        $env:ANTHROPIC_API_KEY = $apiKey
        Write-Host "  Key saved." -ForegroundColor Green
    } else {
        $env:ANTHROPIC_API_KEY = $existingKey
        Write-Host "  ANTHROPIC_API_KEY: OK" -ForegroundColor Green
    }
    $env:ANTHROPIC_BASE_URL = ""
    $env:ANTHROPIC_MODEL    = ""
    $env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = ""
    Write-Host ""
    Write-Host "  Launching Claude Code -> Anthropic Cloud..." -ForegroundColor Magenta

# ---- local mode ---------------------------------------------
} else {
    Write-Banner "Claude Code -> Local Ollama" "Green"

    # Ensure ollama is running
    if (Test-OllamaRunning) {
        Write-Host "  Ollama: already running on port $OLLAMA_PORT" -ForegroundColor Green
    } else {
        $ok = Start-OllamaServer
        if (-not $ok) { exit 1 }
    }

    # Fetch available models from Ollama
    $modelNames = @()
    try {
        $tags = Invoke-RestMethod -Uri $HEALTH_URL -TimeoutSec 3
        $modelNames = $tags.models | ForEach-Object { $_.name }
    } catch {}

    $defaultModel = "qwen3.5:0.8b-32k"

    if ($modelNames.Count -eq 0) {
        Write-Host "  WARNING: Could not fetch models from Ollama, defaulting to $defaultModel" -ForegroundColor Yellow
        $modelNames = @($defaultModel)
    }

    # Sort: default model first, rest alphabetically
    $modelNames = @(
        $modelNames | Where-Object { $_ -eq $defaultModel }
        $modelNames | Where-Object { $_ -ne $defaultModel } | Sort-Object
    )

    # Arrow-key model picker
    $selected = 0
    Write-Host ""
    Write-Host "  Select model (↑↓ arrows + Enter):" -ForegroundColor Cyan
    Write-Host ""

    # Print menu items once to claim the lines
    foreach ($m in $modelNames) { Write-Host "" }
    $menuBottom = [Console]::CursorTop
    $menuTop    = $menuBottom - $modelNames.Count

    function Draw-Menu {
        for ($i = 0; $i -lt $modelNames.Count; $i++) {
            [Console]::SetCursorPosition(0, $menuTop + $i)
            $line = if ($i -eq $script:selected) { "  > $($modelNames[$i])" } else { "    $($modelNames[$i])" }
            # Pad to full width to overwrite any previous content
            $line = $line.PadRight([Console]::WindowWidth - 1)
            if ($i -eq $script:selected) {
                Write-Host $line -ForegroundColor Green -NoNewline
            } else {
                Write-Host $line -ForegroundColor Gray -NoNewline
            }
        }
        [Console]::SetCursorPosition(0, $menuBottom)
    }

    [Console]::CursorVisible = $false
    Draw-Menu
    $pickDone = $false
    while (-not $pickDone) {
        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            "UpArrow"   { if ($script:selected -gt 0)                          { $script:selected-- }; Draw-Menu }
            "DownArrow" { if ($script:selected -lt ($modelNames.Count - 1))    { $script:selected++ }; Draw-Menu }
            "Enter"     { $pickDone = $true }
        }
    }
    [Console]::CursorVisible = $true
    Write-Host ""

    $chosenModel = $modelNames[$selected]

    $env:ANTHROPIC_BASE_URL = "http://localhost:$OLLAMA_PORT"
    $env:ANTHROPIC_API_KEY  = "ollama"
    $env:ANTHROPIC_MODEL    = $chosenModel
    $env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
    $env:OLLAMA_HOST        = $OLLAMA_HOST

    Write-Host "  ANTHROPIC_BASE_URL -> http://localhost:$OLLAMA_PORT" -ForegroundColor DarkGray
    Write-Host "  ANTHROPIC_MODEL    -> $chosenModel" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Launching Claude Code -> Local..." -ForegroundColor Green
}

# ---- launch -------------------------------------------------
Write-Host ""
if ($Dir -and (Test-Path $Dir)) {
    Set-Location $Dir
    Write-Host "  Working dir: $Dir" -ForegroundColor Gray
}

$env:MAX_THINKING_TOKENS                   = "0"
$env:CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING = "1"

& $CLAUDE_CMD