# start_n8n.ps1
# -------------------------------------------------------
# Starts n8n locally and opens the browser.
# Run this from your repo root before sleeping.
#
# Usage:
#   .\tools\start_n8n.ps1
# -------------------------------------------------------

$repoRoot = "c:\horaizon-3.0"
$dataDir  = "$repoRoot\.n8n"
$port     = 5678

Write-Host ""
Write-Host "=================================================="
Write-Host " horAIzon 3.0 — n8n Loop Engineering"
Write-Host "=================================================="
Write-Host " Data dir:  $dataDir"
Write-Host " URL:       http://localhost:$port"
Write-Host "=================================================="
Write-Host ""

# Create data dir if it doesn't exist
if (-not (Test-Path $dataDir)) {
    New-Item -ItemType Directory -Path $dataDir | Out-Null
    Write-Host "[n8n] Created data directory: $dataDir"
}

# Set n8n environment variables
$env:N8N_USER_FOLDER    = $dataDir
$env:N8N_PORT           = $port
$env:N8N_HOST           = "localhost"
$env:N8N_PROTOCOL       = "http"
# Disable telemetry
$env:N8N_DIAGNOSTICS_ENABLED = "false"
$env:N8N_VERSION_NOTIFICATIONS_ENABLED = "false"
# Allow local execute-command nodes
$env:N8N_ALLOW_EXEC     = "true"

Write-Host "[n8n] Starting n8n on http://localhost:$port ..."
Write-Host "[n8n] Press Ctrl+C to stop."
Write-Host ""

# Open browser after 4 seconds
Start-Job -ScriptBlock {
    Start-Sleep -Seconds 4
    Start-Process "http://localhost:5678"
} | Out-Null

# Start n8n
n8n start
